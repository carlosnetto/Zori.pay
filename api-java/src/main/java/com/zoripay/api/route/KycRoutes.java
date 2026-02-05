package com.zoripay.api.route;

import com.zoripay.api.AppState;
import com.zoripay.api.crypto.EncryptionService;
import com.zoripay.api.crypto.WalletService;
import com.zoripay.api.dao.KycDao;
import com.zoripay.api.error.ApiError;
import com.zoripay.api.error.ApiException;
import com.zoripay.api.model.response.AccountOpeningResponse;
import io.javalin.http.Context;
import io.javalin.http.UploadedFile;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

public class KycRoutes {

    private static final Logger log = LoggerFactory.getLogger(KycRoutes.class);
    private final AppState state;
    private final KycDao kycDao;

    public KycRoutes(AppState state) {
        this.state = state;
        this.kycDao = new KycDao(state.jdbi());
    }

    private record FileData(String name, String contentType, byte[] data) {}

    /** POST /v1/kyc/open-account-br */
    public void openAccountBr(Context ctx) {
        // 1. Parse form data
        String fullName = requireFormParam(ctx, "full_name");
        String motherName = requireFormParam(ctx, "mother_name");
        String cpfRaw = requireFormParam(ctx, "cpf");
        String email = requireFormParam(ctx, "email");
        String phone = requireFormParam(ctx, "phone");

        // Parse files
        FileData cnhPdf = readFile(ctx, "cnh_pdf");
        FileData cnhFront = readFile(ctx, "cnh_front");
        FileData cnhBack = readFile(ctx, "cnh_back");
        FileData selfie = readFile(ctx, "selfie");
        FileData proofOfAddress = readFile(ctx, "proof_of_address");

        // Check file sizes
        long totalSize = 0;
        for (var file : List.of(cnhPdf, cnhFront, cnhBack, selfie, proofOfAddress)) {
            if (file != null) {
                if (file.data.length > state.config().maxFileSizeBytes()) {
                    throw new ApiException(new ApiError.FileTooLarge(
                            file.name + " exceeds max size of "
                                    + state.config().maxFileSizeBytes() / 1024 / 1024 + " MB"));
                }
                totalSize += file.data.length;
            }
        }
        if (totalSize > state.config().maxTotalUploadBytes()) {
            throw new ApiException(new ApiError.FileTooLarge(
                    "Total upload size exceeds max of "
                            + state.config().maxTotalUploadBytes() / 1024 / 1024 + " MB"));
        }

        // 2. Validate inputs
        String cpf = validateCpf(cpfRaw);

        if (!email.contains("@") || !email.contains(".")) {
            throw new ApiException(new ApiError.InvalidEmail());
        }

        if (!phone.startsWith("+") || phone.length() < 10) {
            throw new ApiException(new ApiError.InvalidPhone());
        }

        if (selfie == null) {
            throw new ApiException(new ApiError.MissingFile("selfie"));
        }
        if (proofOfAddress == null) {
            throw new ApiException(new ApiError.MissingFile("proof_of_address"));
        }
        if (cnhPdf == null && (cnhFront == null || cnhBack == null)) {
            throw new ApiException(new ApiError.InvalidRequest(
                    "Must provide either CNH PDF or both front and back images"));
        }

        // 3. Check CPF uniqueness
        if (kycDao.cpfExists(cpf)) {
            throw new ApiException(new ApiError.CpfAlreadyExists());
        }

        // 4. Generate and encrypt wallet
        var wallet = WalletService.generateWallet();
        var encrypted = EncryptionService.encryptSeed(wallet.seed(),
                state.config().masterEncryptionKey());

        // 5. Create account in DB transaction
        var result = kycDao.createAccountWithWallet(
                fullName, motherName, cpf, email, phone,
                encrypted.ciphertext(), encrypted.iv(), encrypted.authTag(),
                state.config().encryptionKeyId(), wallet.polygonAddress());

        // 6. Background Drive upload
        var filesToUpload = extractFilesForUpload(cnhPdf, cnhFront, cnhBack, selfie,
                proofOfAddress);
        var driveClient = state.driveClient();
        String cpfForUpload = cpf;

        Thread.startVirtualThread(() -> {
            try {
                String folderId = driveClient.ensureCpfFolder(cpfForUpload);
                for (var file : filesToUpload) {
                    driveClient.uploadFile(file.data, file.name, file.contentType, folderId);
                }
                log.info("Documents uploaded successfully");
            } catch (Exception e) {
                log.error("Failed to upload documents: {}", e.getMessage());
            }
        });

        // 7. Return response
        ctx.json(new AccountOpeningResponse(
                true, result.personId(), result.accountHolderId(),
                result.polygonAddress(),
                "Account created successfully", "processing"
        ));
    }

    private String requireFormParam(Context ctx, String name) {
        String value = ctx.formParam(name);
        if (value == null || value.isBlank()) {
            throw new ApiException(new ApiError.MissingFile(name));
        }
        return value;
    }

    private FileData readFile(Context ctx, String name) {
        UploadedFile file = ctx.uploadedFile(name);
        if (file == null) return null;
        try {
            byte[] data = file.content().readAllBytes();
            return new FileData(
                    file.filename() != null ? file.filename() : name + ".bin",
                    file.contentType() != null ? file.contentType() : "application/octet-stream",
                    data
            );
        } catch (Exception e) {
            throw new ApiException(new ApiError.InvalidRequest("Error reading file: " + name));
        }
    }

    private List<FileData> extractFilesForUpload(FileData cnhPdf, FileData cnhFront,
                                                   FileData cnhBack, FileData selfie,
                                                   FileData proofOfAddress) {
        var files = new ArrayList<FileData>();
        String timestamp = ZonedDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));

        if (cnhPdf != null) {
            files.add(new FileData("cnh_" + timestamp + "." + getExtension(cnhPdf.name),
                    cnhPdf.contentType, cnhPdf.data));
        } else {
            if (cnhFront != null) {
                files.add(new FileData("cnh_front_" + timestamp + "."
                        + getExtension(cnhFront.name), cnhFront.contentType, cnhFront.data));
            }
            if (cnhBack != null) {
                files.add(new FileData("cnh_back_" + timestamp + "."
                        + getExtension(cnhBack.name), cnhBack.contentType, cnhBack.data));
            }
        }

        if (selfie != null) {
            files.add(new FileData("selfie_" + timestamp + "." + getExtension(selfie.name),
                    selfie.contentType, selfie.data));
        }

        if (proofOfAddress != null) {
            files.add(new FileData("proof_of_address_" + timestamp + "."
                    + getExtension(proofOfAddress.name),
                    proofOfAddress.contentType, proofOfAddress.data));
        }

        return files;
    }

    private static String getExtension(String filename) {
        int dot = filename.lastIndexOf('.');
        return dot >= 0 ? filename.substring(dot + 1) : "bin";
    }

    // ==================== CPF Validation ====================

    static String validateCpf(String cpf) {
        String digits = cpf.replaceAll("\\D", "");

        if (digits.length() != 11) {
            throw new ApiException(new ApiError.InvalidCpf("Must be 11 digits"));
        }

        // Check all same digit
        if (digits.chars().distinct().count() == 1) {
            throw new ApiException(new ApiError.InvalidCpf("Invalid CPF"));
        }

        if (!validateCpfChecksum(digits)) {
            throw new ApiException(new ApiError.InvalidCpf("Invalid checksum"));
        }

        return digits;
    }

    static boolean validateCpfChecksum(String cpf) {
        int[] d = new int[11];
        for (int i = 0; i < 11; i++) {
            d[i] = cpf.charAt(i) - '0';
        }

        // First check digit
        int sum = 0;
        for (int i = 0; i < 9; i++) {
            sum += d[i] * (10 - i);
        }
        int remainder = sum % 11;
        int check1 = remainder < 2 ? 0 : 11 - remainder;
        if (check1 != d[9]) return false;

        // Second check digit
        sum = 0;
        for (int i = 0; i < 10; i++) {
            sum += d[i] * (11 - i);
        }
        remainder = sum % 11;
        int check2 = remainder < 2 ? 0 : 11 - remainder;
        return check2 == d[10];
    }
}
