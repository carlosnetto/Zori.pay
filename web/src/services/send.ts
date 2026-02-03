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

export interface SendRequest {
  to_address: string;
  amount: string;
  currency_code: string;
}

export interface SendResponse {
  success: boolean;
  transaction_hash: string;
  message: string;
}

export interface EstimateRequest {
  to_address: string;
  amount: string;
  currency_code: string;
}

export interface EstimateResponse {
  estimated_gas: string;
  gas_price: string;
  estimated_fee: string;
  estimated_fee_formatted: string;
  max_amount: string;
  max_amount_formatted: string;
}

class SendService {
  /**
   * Estimate transaction cost and get max sendable amount
   */
  async estimateTransaction(request: EstimateRequest): Promise<EstimateResponse> {
    const accessToken = localStorage.getItem('access_token');

    if (!accessToken) {
      throw new Error('No access token found. Please log in.');
    }

    try {
      const response = await axios.post<EstimateResponse>(`${API_BASE}/send/estimate`, request, {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        }
      });

      return response.data;
    } catch (error: any) {
      if (error.response?.status === 401) {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('user');
        throw new Error('Session expired. Please log in again.');
      }
      throw new Error(error.response?.data?.error || 'Failed to estimate transaction');
    }
  }

  /**
   * Send cryptocurrency to a destination address
   */
  async sendTransaction(request: SendRequest): Promise<SendResponse> {
    const accessToken = localStorage.getItem('access_token');

    if (!accessToken) {
      throw new Error('No access token found. Please log in.');
    }

    try {
      const response = await axios.post<SendResponse>(`${API_BASE}/send`, request, {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        }
      });

      return response.data;
    } catch (error: any) {
      if (error.response?.status === 401) {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('user');
        throw new Error('Session expired. Please log in again.');
      }
      // Extract error message from response
      const message = error.response?.data?.error || error.message || 'Failed to send transaction';
      throw new Error(message);
    }
  }
}

export const sendService = new SendService();
