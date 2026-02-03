// Copyright (c) 2026 Matera Systems, Inc. All rights reserved.
//
// This source code is the proprietary property of Matera Systems, Inc.
// and is protected by copyright law and international treaties.
//
// This software is NOT open source. Use, reproduction, or distribution
// of this code is strictly governed by the Matera Source License (MSL) v1.0.
//
// A copy of the MSL v1.0 should have been provided with this file.
// If not, please contact: licensing@matera.com

import React, { useState } from 'react';
import { sendService, EstimateResponse } from '../services/send';

interface SendModalProps {
    isOpen: boolean;
    onClose: () => void;
    currencyCode: string;
    currencyName: string;
    balance: string;
    onSuccess?: () => void;
}

type Step = 'input' | 'confirm' | 'sending' | 'success';

const SendModal: React.FC<SendModalProps> = ({
    isOpen,
    onClose,
    currencyCode,
    currencyName,
    balance,
    onSuccess
}) => {
    const [step, setStep] = useState<Step>('input');
    const [destinationAddress, setDestinationAddress] = useState('');
    const [amount, setAmount] = useState('');
    const [error, setError] = useState<string | null>(null);
    const [txHash, setTxHash] = useState<string | null>(null);
    const [estimate, setEstimate] = useState<EstimateResponse | null>(null);
    const [loadingEstimate, setLoadingEstimate] = useState(false);

    const isValidAddress = (address: string) => {
        return /^0x[a-fA-F0-9]{40}$/.test(address);
    };

    const handleSendMax = async () => {
        if (!isValidAddress(destinationAddress)) {
            setError('Please enter a valid destination address first');
            return;
        }

        setLoadingEstimate(true);
        setError(null);

        try {
            const est = await sendService.estimateTransaction({
                to_address: destinationAddress,
                amount: '0',
                currency_code: currencyCode
            });
            setEstimate(est);
            setAmount(est.max_amount_formatted);
        } catch (err: any) {
            setError(err.message || 'Failed to calculate max amount');
        } finally {
            setLoadingEstimate(false);
        }
    };

    const handleContinue = async () => {
        setError(null);

        // Validate address
        if (!isValidAddress(destinationAddress)) {
            setError('Please enter a valid Polygon address (0x...)');
            return;
        }

        // Validate amount
        const amountNum = parseFloat(amount);
        if (isNaN(amountNum) || amountNum <= 0) {
            setError('Please enter a valid amount');
            return;
        }

        const balanceNum = parseFloat(balance.replace(/,/g, ''));
        if (amountNum > balanceNum) {
            setError('Insufficient balance');
            return;
        }

        // Fetch estimate for the confirmation screen
        setLoadingEstimate(true);
        try {
            const est = await sendService.estimateTransaction({
                to_address: destinationAddress,
                amount: amount,
                currency_code: currencyCode
            });
            setEstimate(est);
            setStep('confirm');
        } catch (err: any) {
            setError(err.message || 'Failed to estimate transaction');
        } finally {
            setLoadingEstimate(false);
        }
    };

    const handleConfirmSend = async () => {
        setStep('sending');
        setError(null);

        try {
            const response = await sendService.sendTransaction({
                to_address: destinationAddress,
                amount: amount,
                currency_code: currencyCode
            });

            setTxHash(response.transaction_hash);
            setStep('success');

            if (onSuccess) {
                onSuccess();
            }
        } catch (err: any) {
            setError(err.message || 'Failed to send transaction');
            setStep('confirm');
        }
    };

    const handleClose = () => {
        setDestinationAddress('');
        setAmount('');
        setError(null);
        setTxHash(null);
        setEstimate(null);
        setStep('input');
        onClose();
    };

    const truncateAddress = (address: string) => {
        if (!address) return '';
        return `${address.slice(0, 10)}...${address.slice(-8)}`;
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
            {/* Backdrop */}
            <div
                className="absolute inset-0 bg-black/50 backdrop-blur-sm"
                onClick={step === 'sending' ? undefined : handleClose}
            />

            {/* Modal */}
            <div className="relative bg-white rounded-3xl p-8 max-w-sm w-full mx-4 shadow-2xl">
                {/* Close button (hidden during sending) */}
                {step !== 'sending' && (
                    <button
                        onClick={handleClose}
                        className="absolute top-4 right-4 w-8 h-8 flex items-center justify-center text-gray-400 hover:text-gray-600 transition-colors"
                    >
                        <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                )}

                {/* Step 1: Input */}
                {step === 'input' && (
                    <>
                        <h2 className="text-xl font-black text-gray-900 text-center mb-2">Send {currencyCode}</h2>

                        {/* Currency badge */}
                        <div className="flex justify-center mb-6">
                            <span className="px-4 py-1.5 bg-purple-100 text-purple-700 text-xs font-bold rounded-full uppercase tracking-wider">
                                POLYGON
                            </span>
                        </div>

                        {/* Balance info */}
                        <div className="text-center mb-6">
                            <p className="text-sm text-gray-500">Available balance</p>
                            <p className="text-lg font-bold text-gray-900">{balance} {currencyCode}</p>
                        </div>

                        {/* Destination address input */}
                        <div className="mb-4">
                            <label className="block text-sm text-gray-600 mb-2">
                                Type here the destination Polygon address for <span className="font-bold">{currencyName}</span>
                            </label>
                            <input
                                type="text"
                                value={destinationAddress}
                                onChange={(e) => setDestinationAddress(e.target.value)}
                                placeholder="0x..."
                                className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl font-mono text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                            />
                        </div>

                        {/* Amount input */}
                        <div className="mb-6">
                            <label className="block text-sm text-gray-600 mb-2">
                                Amount to send
                            </label>
                            <div className="relative">
                                <input
                                    type="number"
                                    value={amount}
                                    onChange={(e) => setAmount(e.target.value)}
                                    placeholder="0.00"
                                    step="0.000001"
                                    min="0"
                                    className="w-full px-4 py-3 pr-20 bg-gray-50 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                                />
                                <span className="absolute right-4 top-1/2 -translate-y-1/2 text-sm font-bold text-gray-400">
                                    {currencyCode}
                                </span>
                            </div>
                            <button
                                onClick={handleSendMax}
                                disabled={loadingEstimate}
                                className="mt-2 text-xs text-blue-600 font-bold hover:text-blue-700 disabled:opacity-50"
                            >
                                {loadingEstimate ? 'Calculating...' : 'Send max'}
                            </button>
                        </div>

                        {/* Error message */}
                        {error && (
                            <div className="mb-4 p-3 bg-red-50 border border-red-100 rounded-xl">
                                <p className="text-sm text-red-600">{error}</p>
                            </div>
                        )}

                        {/* Continue button */}
                        <button
                            onClick={handleContinue}
                            disabled={!destinationAddress || !amount || loadingEstimate}
                            className="w-full py-4 bg-blue-600 text-white font-bold rounded-2xl hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
                        >
                            {loadingEstimate ? (
                                <>
                                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                                    Estimating...
                                </>
                            ) : (
                                'Continue'
                            )}
                        </button>
                    </>
                )}

                {/* Step 2: Confirm */}
                {step === 'confirm' && (
                    <>
                        <h2 className="text-xl font-black text-gray-900 text-center mb-6">Confirm Transaction</h2>

                        <div className="bg-gray-50 rounded-2xl p-6 mb-6">
                            {/* Amount */}
                            <div className="text-center mb-6">
                                <p className="text-sm text-gray-500 mb-1">You are sending</p>
                                <p className="text-3xl font-black text-gray-900">{amount} {currencyCode}</p>
                            </div>

                            {/* Destination */}
                            <div className="border-t border-gray-200 pt-4">
                                <p className="text-sm text-gray-500 mb-1">To address</p>
                                <p className="font-mono text-sm text-gray-900 break-all">{destinationAddress}</p>
                            </div>

                            {/* Network */}
                            <div className="border-t border-gray-200 pt-4 mt-4">
                                <p className="text-sm text-gray-500 mb-1">Network</p>
                                <p className="text-sm font-bold text-purple-600">Polygon</p>
                            </div>

                            {/* Estimated Fee */}
                            {estimate && (
                                <div className="border-t border-gray-200 pt-4 mt-4">
                                    <p className="text-sm text-gray-500 mb-1">Estimated network fee</p>
                                    <p className="text-sm font-bold text-gray-900">{estimate.estimated_fee_formatted} POL</p>
                                </div>
                            )}
                        </div>

                        {/* Error message */}
                        {error && (
                            <div className="mb-4 p-3 bg-red-50 border border-red-100 rounded-xl">
                                <p className="text-sm text-red-600">{error}</p>
                            </div>
                        )}

                        {/* Warning */}
                        <div className="mb-6 p-3 bg-yellow-50 border border-yellow-100 rounded-xl">
                            <p className="text-xs text-yellow-700">
                                Please verify the address carefully. Transactions cannot be reversed.
                            </p>
                        </div>

                        {/* Buttons */}
                        <div className="flex space-x-3">
                            <button
                                onClick={() => setStep('input')}
                                className="flex-1 py-4 bg-gray-100 text-gray-700 font-bold rounded-2xl hover:bg-gray-200 transition-colors"
                            >
                                Back
                            </button>
                            <button
                                onClick={handleConfirmSend}
                                className="flex-1 py-4 bg-blue-600 text-white font-bold rounded-2xl hover:bg-blue-700 transition-colors flex items-center justify-center space-x-2"
                            >
                                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 10l7-7m0 0l7 7m-7-7v18" />
                                </svg>
                                <span>Send</span>
                            </button>
                        </div>
                    </>
                )}

                {/* Step 3: Sending */}
                {step === 'sending' && (
                    <div className="py-8 text-center">
                        <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600 mx-auto mb-6"></div>
                        <h2 className="text-xl font-black text-gray-900 mb-2">Sending Transaction</h2>
                        <p className="text-sm text-gray-500">Please wait while we process your transaction...</p>
                    </div>
                )}

                {/* Step 4: Success */}
                {step === 'success' && (
                    <div className="py-4 text-center">
                        <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
                            <svg className="w-8 h-8 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                            </svg>
                        </div>
                        <h2 className="text-xl font-black text-gray-900 mb-2">Transaction Sent!</h2>
                        <p className="text-sm text-gray-500 mb-6">
                            Your {amount} {currencyCode} has been sent successfully.
                        </p>

                        {txHash && (
                            <div className="mb-6">
                                <p className="text-xs text-gray-400 mb-1">Transaction Hash</p>
                                <a
                                    href={`https://polygonscan.com/tx/${txHash}`}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="font-mono text-xs text-blue-600 hover:text-blue-700 break-all"
                                >
                                    {truncateAddress(txHash)} ↗
                                </a>
                            </div>
                        )}

                        <button
                            onClick={handleClose}
                            className="w-full py-4 bg-blue-600 text-white font-bold rounded-2xl hover:bg-blue-700 transition-colors"
                        >
                            Done
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
};

export default SendModal;
