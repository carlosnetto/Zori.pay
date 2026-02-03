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

import React, { useState, useEffect } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { receiveService, ReceiveAddressResponse } from '../services/receive';

interface ReceiveModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const ReceiveModal: React.FC<ReceiveModalProps> = ({ isOpen, onClose }) => {
  const [addressData, setAddressData] = useState<ReceiveAddressResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (isOpen) {
      fetchAddress();
    }
  }, [isOpen]);

  const fetchAddress = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await receiveService.getReceiveAddress();
      setAddressData(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load address');
    } finally {
      setLoading(false);
    }
  };

  const handleCopy = async () => {
    if (!addressData?.address) return;

    try {
      await navigator.clipboard.writeText(addressData.address);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal */}
      <div className="relative bg-white rounded-3xl p-8 max-w-sm w-full mx-4 shadow-2xl">
        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 w-8 h-8 flex items-center justify-center text-gray-400 hover:text-gray-600 transition-colors"
        >
          <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        {/* Title */}
        <h2 className="text-xl font-black text-gray-900 text-center mb-6">Receive Funds</h2>

        {loading ? (
          <div className="flex flex-col items-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mb-4"></div>
            <p className="text-sm text-gray-500">Loading address...</p>
          </div>
        ) : error ? (
          <div className="text-center py-8">
            <div className="text-4xl mb-4">⚠️</div>
            <p className="text-sm text-red-600 mb-4">{error}</p>
            <button
              onClick={fetchAddress}
              className="px-6 py-2 bg-blue-600 text-white text-sm font-bold rounded-full hover:bg-blue-700"
            >
              Retry
            </button>
          </div>
        ) : addressData && (
          <>
            {/* Blockchain badge */}
            <div className="flex justify-center mb-6">
              <span className="px-4 py-1.5 bg-purple-100 text-purple-700 text-xs font-bold rounded-full uppercase tracking-wider">
                {addressData.blockchain}
              </span>
            </div>

            {/* QR Code */}
            <div className="flex justify-center mb-6">
              <div className="p-4 bg-white rounded-2xl border-2 border-gray-100 shadow-sm">
                <QRCodeSVG
                  value={addressData.address}
                  size={200}
                  level="H"
                  includeMargin={true}
                />
              </div>
            </div>

            {/* Address with copy button */}
            <div className="relative">
              <div
                onClick={handleCopy}
                className="flex items-center justify-between p-4 bg-gray-50 rounded-2xl border border-gray-200 cursor-pointer hover:bg-gray-100 transition-colors group"
              >
                <p className="font-mono text-xs text-gray-600 break-all pr-3">
                  {addressData.address}
                </p>
                <div className="flex-shrink-0">
                  {copied ? (
                    <svg className="w-5 h-5 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                  ) : (
                    <svg className="w-5 h-5 text-gray-400 group-hover:text-gray-600 transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                    </svg>
                  )}
                </div>
              </div>
              {copied && (
                <p className="text-center text-xs text-green-600 font-medium mt-2">
                  Address copied!
                </p>
              )}
            </div>

            {/* Warning */}
            <p className="text-center text-xs text-gray-400 mt-6">
              Only send tokens on the {addressData.blockchain} network to this address
            </p>
          </>
        )}
      </div>
    </div>
  );
};

export default ReceiveModal;
