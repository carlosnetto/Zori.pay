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

// Storage keys
const STORAGE_KEY = 'zori_reference_data';
const ETAG_KEY = 'zori_reference_data_etag';

// Types
export interface Country {
  iso_code: string;
  name: string;
}

export interface State {
  country_code: string;
  state_code: string;
  name: string;
}

export interface PhoneType {
  code: string;
  description: string;
}

export interface EmailType {
  code: string;
  description: string;
}

export interface Currency {
  code: string;
  name: string;
  asset_type_code: string;
  decimals: number;
}

export interface BlockchainNetwork {
  code: string;
  name: string;
}

export interface AddressType {
  code: string;
  description: string;
}

export interface AssetType {
  code: string;
  description: string;
}

export interface ReferenceData {
  countries: Country[];
  states: State[];
  phone_types: PhoneType[];
  email_types: EmailType[];
  currencies: Currency[];
  blockchain_networks: BlockchainNetwork[];
  address_types: AddressType[];
  asset_types: AssetType[];
}

// In-memory cache
let cachedData: ReferenceData | null = null;
let cachedEtag: string | null = null;

class ReferenceDataService {
  /**
   * Fetch reference data from API with caching support.
   * Uses sessionStorage for persistence and ETag for cache validation.
   */
  async getReferenceData(): Promise<ReferenceData> {
    // Check in-memory cache first
    if (cachedData) {
      return cachedData;
    }

    // Check sessionStorage
    const storedData = sessionStorage.getItem(STORAGE_KEY);
    const storedEtag = sessionStorage.getItem(ETAG_KEY);

    if (storedData && storedEtag) {
      try {
        // Try conditional request with If-None-Match
        const response = await axios.get<ReferenceData>(`${API_BASE}/reference-data`, {
          headers: {
            'If-None-Match': storedEtag
          },
          validateStatus: (status) => status === 200 || status === 304
        });

        if (response.status === 304) {
          // Data hasn't changed, use cached version
          cachedData = JSON.parse(storedData);
          cachedEtag = storedEtag;
          return cachedData;
        }

        // Data changed, update cache
        cachedData = response.data;
        cachedEtag = response.headers['etag'] || null;

        sessionStorage.setItem(STORAGE_KEY, JSON.stringify(cachedData));
        if (cachedEtag) {
          sessionStorage.setItem(ETAG_KEY, cachedEtag);
        }

        return cachedData;
      } catch {
        // On error, fall back to stored data
        cachedData = JSON.parse(storedData);
        cachedEtag = storedEtag;
        return cachedData;
      }
    }

    // No cache, fetch fresh data
    const response = await axios.get<ReferenceData>(`${API_BASE}/reference-data`);

    cachedData = response.data;
    cachedEtag = response.headers['etag'] || null;

    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(cachedData));
    if (cachedEtag) {
      sessionStorage.setItem(ETAG_KEY, cachedEtag);
    }

    return cachedData;
  }

  /**
   * Get all countries sorted by name
   */
  async getCountries(): Promise<Country[]> {
    const data = await this.getReferenceData();
    return data.countries;
  }

  /**
   * Get states for a specific country
   */
  async getStatesForCountry(countryCode: string): Promise<State[]> {
    const data = await this.getReferenceData();
    return data.states.filter(s => s.country_code === countryCode);
  }

  /**
   * Get all phone types
   */
  async getPhoneTypes(): Promise<PhoneType[]> {
    const data = await this.getReferenceData();
    return data.phone_types;
  }

  /**
   * Get all email types
   */
  async getEmailTypes(): Promise<EmailType[]> {
    const data = await this.getReferenceData();
    return data.email_types;
  }

  /**
   * Get all currencies
   */
  async getCurrencies(): Promise<Currency[]> {
    const data = await this.getReferenceData();
    return data.currencies;
  }

  /**
   * Get currencies by asset type (fiat, crypto, stablecoin)
   */
  async getCurrenciesByType(assetType: string): Promise<Currency[]> {
    const data = await this.getReferenceData();
    return data.currencies.filter(c => c.asset_type_code === assetType);
  }

  /**
   * Get all blockchain networks
   */
  async getBlockchainNetworks(): Promise<BlockchainNetwork[]> {
    const data = await this.getReferenceData();
    return data.blockchain_networks;
  }

  /**
   * Get all address types
   */
  async getAddressTypes(): Promise<AddressType[]> {
    const data = await this.getReferenceData();
    return data.address_types;
  }

  /**
   * Get all asset types
   */
  async getAssetTypes(): Promise<AssetType[]> {
    const data = await this.getReferenceData();
    return data.asset_types;
  }

  /**
   * Clear the cache (useful for testing or forcing refresh)
   */
  clearCache(): void {
    cachedData = null;
    cachedEtag = null;
    sessionStorage.removeItem(STORAGE_KEY);
    sessionStorage.removeItem(ETAG_KEY);
  }
}

export const referenceDataService = new ReferenceDataService();
