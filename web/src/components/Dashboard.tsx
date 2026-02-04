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
import { Language, translations } from '../translations';
import { CurrencySymbol, WalletBalance } from '../types';
import { balanceService } from '../services/balance';
import { transactionsService, Transaction } from '../services/transactions';
import ReceiveModal from './ReceiveModal';
import SendModal from './SendModal';

interface DashboardProps {
    currentLang: Language;
}

interface TransactionsData {
    address: string;
    blockchain: string;
    currency_code: string | null;
    transactions: Transaction[];
}

// Currency metadata (icons, colors, names)
const CURRENCY_METADATA: Record<string, { name: string; color: string; icon: string }> = {
    'BRL1': { name: 'Zori Real', color: 'bg-yellow-500', icon: '/images/brl1.png' },
    'USDC': { name: 'Digital Dollar', color: 'bg-blue-600', icon: '/images/usdc.svg' },
    'USDT': { name: 'Tether', color: 'bg-green-500', icon: '/images/usdt.svg' },
    'ETH': { name: 'Ethereum', color: 'bg-indigo-600', icon: '/images/eth.svg' },
    'POL': { name: 'Polygon', color: 'bg-purple-600', icon: '/images/pol.png' },
};


const Dashboard: React.FC<DashboardProps> = ({ currentLang }) => {
    const t = translations[currentLang].dashboard;
    const [activeCurrency, setActiveCurrency] = useState<CurrencySymbol>('POL');
    const [balances, setBalances] = useState<WalletBalance[]>([]);
    const [transactions, setTransactions] = useState<Transaction[]>([]);
    const [userAddress, setUserAddress] = useState<string>('');
    const [loading, setLoading] = useState(true);
    const [loadingTransactions, setLoadingTransactions] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [showReceiveModal, setShowReceiveModal] = useState(false);
    const [showSendModal, setShowSendModal] = useState(false);
    const [refreshing, setRefreshing] = useState(false);

    // Fetch balances on component mount
    useEffect(() => {
        const fetchBalances = async () => {
            try {
                setLoading(true);
                setError(null);
                const response = await balanceService.getBalances();

                // Map API response to WalletBalance format
                const walletBalances: WalletBalance[] = response.balances.map(balance => {
                    const metadata = CURRENCY_METADATA[balance.currency_code] || {
                        name: balance.currency_code,
                        color: 'bg-gray-600',
                        icon: '/images/default.png'
                    };

                    return {
                        symbol: balance.currency_code as CurrencySymbol,
                        name: metadata.name,
                        balance: balance.formatted_balance,
                        color: metadata.color,
                        icon: metadata.icon
                    };
                });

                setBalances(walletBalances);

                // Set first available currency as active
                if (walletBalances.length > 0) {
                    setActiveCurrency(walletBalances[0].symbol);
                }
            } catch (err: any) {
                console.error('Failed to fetch balances:', err);
                setError(err.message || 'Failed to load balances');
            } finally {
                setLoading(false);
            }
        };

        fetchBalances();
    }, []);

    // Fetch transactions when currency changes
    useEffect(() => {
        const fetchTransactions = async () => {
            try {
                setLoadingTransactions(true);
                const response = await transactionsService.getTransactions(activeCurrency, 20);
                setTransactions(response.transactions);
                setUserAddress(response.address.toLowerCase());
            } catch (err: any) {
                console.error('Failed to fetch transactions:', err);
                // Don't show error for transactions, just log it
            } finally {
                setLoadingTransactions(false);
            }
        };

        if (activeCurrency) {
            fetchTransactions();
        }
    }, [activeCurrency]);

    // Refresh both balances and transactions
    const handleRefresh = async () => {
        setRefreshing(true);
        try {
            // Fetch balances
            const response = await balanceService.getBalances();
            const walletBalances: WalletBalance[] = response.balances.map(balance => {
                const metadata = CURRENCY_METADATA[balance.currency_code] || {
                    name: balance.currency_code,
                    color: 'bg-gray-600',
                    icon: '/images/default.png'
                };
                return {
                    symbol: balance.currency_code as CurrencySymbol,
                    name: metadata.name,
                    balance: balance.formatted_balance,
                    color: metadata.color,
                    icon: metadata.icon
                };
            });
            setBalances(walletBalances);

            // Fetch transactions
            const txResponse = await transactionsService.getTransactions(activeCurrency, 20);
            setTransactions(txResponse.transactions);
            setUserAddress(txResponse.address.toLowerCase());
        } catch (err: any) {
            console.error('Refresh failed:', err);
        } finally {
            setRefreshing(false);
        }
    };

    const activeWallet = balances.find(b => b.symbol === activeCurrency) || balances[0];

    // Helper to truncate blockchain addresses
    const truncateAddress = (address: string) => {
        if (!address) return '';
        return `${address.slice(0, 6)}...${address.slice(-4)}`;
    };

    // Helper to format timestamp
    const formatTimestamp = (timestamp: number) => {
        if (!timestamp || timestamp === 0) return 'Recent';
        const date = new Date(timestamp * 1000);
        const now = new Date();
        const diff = now.getTime() - date.getTime();
        const hours = Math.floor(diff / (1000 * 60 * 60));

        if (hours < 1) return 'Just now';
        if (hours < 24) return `${hours}h ago`;
        const days = Math.floor(hours / 24);
        if (days < 7) return `${days}d ago`;
        return date.toLocaleDateString();
    };

    // Loading state
    if (loading) {
        return (
            <div className="pt-24 pb-12 max-w-lg mx-auto px-4 sm:px-6">
                <div className="flex items-center justify-center min-h-[400px]">
                    <div className="text-center">
                        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
                        <p className="text-sm font-bold text-gray-400 uppercase tracking-widest">Loading balances...</p>
                    </div>
                </div>
            </div>
        );
    }

    // Error state
    if (error) {
        const isSessionExpired = error.toLowerCase().includes('session expired');

        return (
            <div className="pt-24 pb-12 max-w-lg mx-auto px-4 sm:px-6">
                <div className="flex items-center justify-center min-h-[400px]">
                    <div className="text-center bg-red-50 p-8 rounded-3xl border border-red-100">
                        <div className="text-4xl mb-4">{isSessionExpired ? '🔒' : '⚠️'}</div>
                        <p className="text-sm font-bold text-red-600 mb-2">
                            {isSessionExpired ? 'Session Expired' : 'Failed to load balances'}
                        </p>
                        <p className="text-xs text-gray-600 mb-4">{error}</p>
                        {isSessionExpired ? (
                            <button
                                onClick={() => window.location.reload()}
                                className="px-6 py-2 bg-blue-600 text-white text-sm font-bold rounded-full hover:bg-blue-700"
                            >
                                Login again
                            </button>
                        ) : (
                            <button
                                onClick={() => window.location.reload()}
                                className="px-6 py-2 bg-red-600 text-white text-sm font-bold rounded-full hover:bg-red-700"
                            >
                                Retry
                            </button>
                        )}
                    </div>
                </div>
            </div>
        );
    }

    // No balances found
    if (balances.length === 0) {
        return (
            <div className="pt-24 pb-12 max-w-lg mx-auto px-4 sm:px-6">
                <div className="flex items-center justify-center min-h-[400px]">
                    <div className="text-center">
                        <div className="text-4xl mb-4 opacity-20">💰</div>
                        <p className="text-sm font-bold text-gray-400 uppercase tracking-widest">No balances found</p>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="pt-24 pb-12 max-w-lg mx-auto px-4 sm:px-6">
            {/* Horizontal Currency Selector */}
            <div className="flex space-x-3 mb-8 overflow-x-auto pb-2 scrollbar-hide no-scrollbar">
                {balances.map((wallet) => (
                    <button
                        key={wallet.symbol}
                        onClick={() => setActiveCurrency(wallet.symbol)}
                        className={`
              flex flex-col items-center justify-center w-20 h-20 rounded-2xl transition-all duration-300 border-2
              ${activeCurrency === wallet.symbol
                                ? `${wallet.color} border-transparent text-white shadow-lg scale-105 ring-4 ring-gray-100`
                                : 'bg-white border-gray-100 text-gray-400 hover:border-gray-200'}
            `}
                    >
                        <div className={`w-8 h-8 rounded-full overflow-hidden bg-white flex items-center justify-center mb-1 ${activeCurrency === wallet.symbol ? '' : 'grayscale opacity-60'}`}>
                            <img src={wallet.icon} alt={wallet.symbol} className="w-full h-full object-cover" />
                        </div>
                        <span className="text-[9px] font-black uppercase tracking-tighter">{wallet.symbol}</span>
                    </button>
                ))}
            </div>

            {/* Main Balance Card */}
            <div className={`relative overflow-hidden rounded-[2.5rem] p-8 text-white shadow-xl mb-10 transition-colors duration-500 ${activeWallet.color}`}>
                <div className="absolute top-0 right-0 w-64 h-64 bg-white opacity-5 rounded-full -translate-y-1/2 translate-x-1/3"></div>

                {/* Refresh button */}
                <button
                    onClick={handleRefresh}
                    disabled={refreshing}
                    className="absolute top-6 right-6 w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center hover:bg-white/30 transition-colors z-20 disabled:opacity-50"
                >
                    <svg
                        className={`w-5 h-5 text-white ${refreshing ? 'animate-spin' : ''}`}
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                    </svg>
                </button>

                <div className="relative z-10">
                    <div className="flex items-center space-x-3 mb-2">
                        <div className="w-8 h-8 rounded-full overflow-hidden bg-white">
                            <img src={activeWallet.icon} alt={activeWallet.symbol} className="w-full h-full object-cover" />
                        </div>
                        <span className="text-sm font-medium opacity-80">{activeWallet.name}</span>
                    </div>
                    <div className="flex items-baseline space-x-2 mb-8">
                        <span className="text-4xl md:text-5xl font-black tabular-nums">
                            {activeWallet.balance}
                        </span>
                        <span className="text-lg font-bold opacity-60">{activeWallet.symbol}</span>
                    </div>

                    <div className="flex justify-center items-center space-x-16">
                        <button onClick={() => setShowSendModal(true)} className="flex flex-col items-center space-y-2 group">
                            <div className="w-14 h-14 bg-white/20 rounded-2xl flex items-center justify-center group-hover:bg-white/30 transition-colors">
                                <svg className="w-7 h-7 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 10l7-7m0 0l7 7m-7-7v18" /></svg>
                            </div>
                            <span className="text-xs font-bold uppercase tracking-wider">{t.send}</span>
                        </button>
                        <button onClick={() => setShowReceiveModal(true)} className="flex flex-col items-center space-y-2 group">
                            <div className="w-14 h-14 bg-white/20 rounded-2xl flex items-center justify-center group-hover:bg-white/30 transition-colors">
                                <svg className="w-7 h-7 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" /></svg>
                            </div>
                            <span className="text-xs font-bold uppercase tracking-wider">{t.receive}</span>
                        </button>
                    </div>
                </div>
            </div>

            {/* Transactions List */}
            <div>
                <div className="flex items-center justify-between mb-6 px-2">
                    <h3 className="text-xl font-black text-gray-900">{t.transactions}</h3>
                    <span className="text-xs font-bold text-gray-400 uppercase tracking-widest">{activeCurrency}</span>
                </div>

                <div className="space-y-3">
                    {loadingTransactions ? (
                        <div className="text-center py-10">
                            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
                        </div>
                    ) : transactions.length > 0 ? (
                        transactions.map((tx) => {
                            const isSent = tx.from.toLowerCase() === userAddress;
                            const displayAddress = isSent ? tx.to : tx.from;

                            return (
                                <div key={tx.hash} className="bg-white p-5 rounded-3xl border border-gray-100 shadow-sm group hover:border-blue-100 transition-colors">
                                    <div className="flex items-center justify-between mb-3">
                                        <div className="flex items-center space-x-3">
                                            <div className={`w-10 h-10 rounded-full flex items-center justify-center text-sm font-bold ${isSent ? 'bg-red-50 text-red-600' : 'bg-green-50 text-green-600'}`}>
                                                {isSent ? '↑' : '↓'}
                                            </div>
                                            <div>
                                                <p className="font-bold text-gray-900 text-sm">{isSent ? 'Sent' : 'Received'}</p>
                                                <p className="text-[10px] text-gray-400 font-mono">{truncateAddress(displayAddress)}</p>
                                            </div>
                                        </div>
                                        <div className="text-right">
                                            <span className={`text-lg font-black tabular-nums ${isSent ? 'text-red-600' : 'text-green-600'}`}>
                                                {isSent ? '-' : '+'}{tx.formatted_value}
                                            </span>
                                            <p className="text-[10px] font-bold text-gray-400">{tx.currency_code}</p>
                                        </div>
                                    </div>
                                    <div className="flex items-center justify-between text-[10px] text-gray-400">
                                        <span>{formatTimestamp(tx.timestamp)}</span>
                                        <a
                                            href={`https://polygonscan.com/tx/${tx.hash}`}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="font-mono hover:text-blue-600 transition-colors"
                                        >
                                            {truncateAddress(tx.hash)} ↗
                                        </a>
                                    </div>
                                </div>
                            );
                        })
                    ) : (
                        <div className="text-center py-20 bg-gray-50/50 rounded-[2.5rem] border-2 border-dashed border-gray-100">
                            <div className="text-4xl mb-4 opacity-20">🌫️</div>
                            <p className="text-sm font-bold text-gray-400 uppercase tracking-widest">
                                {t.empty}
                            </p>
                        </div>
                    )}
                </div>
            </div>

            {/* Receive Modal */}
            <ReceiveModal
                isOpen={showReceiveModal}
                onClose={() => setShowReceiveModal(false)}
            />

            {/* Send Modal */}
            <SendModal
                isOpen={showSendModal}
                onClose={() => setShowSendModal(false)}
                currencyCode={activeWallet?.symbol || ''}
                currencyName={activeWallet?.name || ''}
                balance={activeWallet?.balance || '0'}
                onSuccess={handleRefresh}
            />
        </div>
    );
};

export default Dashboard;
