import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080/v1';

export interface ReceiveAddressResponse {
  blockchain: string;
  address: string;
}

class ReceiveService {
  /**
   * Fetch the user's blockchain address for receiving funds
   */
  async getReceiveAddress(): Promise<ReceiveAddressResponse> {
    const accessToken = localStorage.getItem('access_token');

    if (!accessToken) {
      throw new Error('No access token found. Please log in.');
    }

    try {
      const response = await axios.get<ReceiveAddressResponse>(`${API_BASE}/receive`, {
        headers: {
          'Authorization': `Bearer ${accessToken}`
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
      throw error;
    }
  }
}

export const receiveService = new ReceiveService();
