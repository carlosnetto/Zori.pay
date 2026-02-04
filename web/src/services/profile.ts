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

import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080/v1';

export interface PersonalInfo {
  full_name: string;
  date_of_birth: string | null;
  birth_city: string | null;
  birth_country: string | null;
}

export interface PhoneInfo {
  phone_number: string;
  phone_type: string | null;
  is_primary_for_login: boolean;
}

export interface EmailInfo {
  email_address: string;
  email_type: string | null;
  is_primary_for_login: boolean;
}

export interface ContactInfo {
  phones: PhoneInfo[];
  emails: EmailInfo[];
}

export interface AddressInfo {
  line1: string | null;
  line2: string | null;
  city: string | null;
  state: string | null;
  postal_code: string | null;
  country: string | null;
}

export interface BlockchainInfo {
  polygon_address: string | null;
}

export interface BrazilBankAccount {
  bank_code: string | null;
  branch_number: string | null;
  account_number: string | null;
}

export interface UsaBankAccount {
  routing_number: string;
  account_number: string;
}

export interface AccountsInfo {
  brazil: BrazilBankAccount | null;
  usa: UsaBankAccount | null;
}

export interface BrazilDocuments {
  cpf: string;
  rg_number: string | null;
  rg_issuer: string | null;
  rg_issued_at: string | null;
}

export interface UsaDocuments {
  ssn_last4: string | null;
  drivers_license_number: string | null;
  drivers_license_state: string | null;
}

export interface DocumentsInfo {
  brazil: BrazilDocuments | null;
  usa: UsaDocuments | null;
}

export interface ProfileResponse {
  personal: PersonalInfo | null;
  contact: ContactInfo | null;
  address: AddressInfo | null;
  blockchain: BlockchainInfo | null;
  accounts: AccountsInfo | null;
  documents: DocumentsInfo | null;
}

class ProfileService {
  /**
   * Fetch profile data for the authenticated user
   */
  async getProfile(): Promise<ProfileResponse> {
    const accessToken = localStorage.getItem('access_token');

    if (!accessToken) {
      throw new Error('No access token found. Please log in.');
    }

    try {
      const response = await axios.get<ProfileResponse>(`${API_BASE}/profile`, {
        headers: {
          'Authorization': `Bearer ${accessToken}`
        }
      });

      return response.data;
    } catch (error: any) {
      if (error.response?.status === 401) {
        // Token expired or invalid
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('user');
        throw new Error('Session expired. Please log in again.');
      }
      throw error;
    }
  }
}

export const profileService = new ProfileService();
