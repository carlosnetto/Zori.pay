import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080/v1';

export interface Transaction {
  hash: string;
  block_number: number;
  timestamp: number;
  from: string;
  to: string;
  value: string;
  formatted_value: string;
  currency_code: string;
  decimals: number;
  status: string;
}

export interface TransactionsResponse {
  address: string;
  blockchain: string;
  currency_code: string | null;
  transactions: Transaction[];
}

class TransactionsService {
  /**
   * Fetch blockchain transactions for the authenticated user
   */
  async getTransactions(currencyCode?: string, limit?: number): Promise<TransactionsResponse> {
    const accessToken = localStorage.getItem('access_token');

    if (!accessToken) {
      throw new Error('No access token found. Please log in.');
    }

    try {
      const params = new URLSearchParams();
      if (currencyCode) params.append('currency_code', currencyCode);
      if (limit) params.append('limit', limit.toString());

      const response = await axios.get<TransactionsResponse>(
        `${API_BASE}/transactions?${params.toString()}`,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`
          }
        }
      );

      return response.data;
    } catch (error: any) {
      if (error.response?.status === 401) {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('user');
        throw new Error('Session expired. Please log in again.');
      }
      throw error;
    }
  }
}

export const transactionsService = new TransactionsService();
