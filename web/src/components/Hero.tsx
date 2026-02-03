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

import React from 'react';
import { Language, translations } from '../translations';

interface HeroProps {
  currentLang: Language;
  onGetZori: () => void;
}

const Hero: React.FC<HeroProps> = ({ currentLang, onGetZori }) => {
  const t = translations[currentLang].hero;

  return (
    <section className="relative pt-32 pb-20 lg:pt-48 lg:pb-32 overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="lg:grid lg:grid-cols-2 lg:gap-8 items-center">
          <div className="z-10">
            <h1 className="text-5xl md:text-7xl font-extrabold text-gray-900 leading-tight mb-6">
              {t.title.includes('.') ? (
                t.title.split('.').map((part, i) => (
                  <React.Fragment key={i}>
                    {i === 1 ? <span className="text-blue-600">{part}</span> : part}
                    {i === 0 && part.length > 0 && '.'}
                  </React.Fragment>
                ))
              ) : (
                <span className="text-blue-600">{t.title}</span>
              )}
            </h1>
            <p className="text-xl text-gray-600 mb-8 max-w-lg leading-relaxed">
              {t.subtitle}
            </p>
            <div className="flex flex-col sm:flex-row space-y-4 sm:space-y-0 sm:space-x-4">
              <button 
                onClick={onGetZori}
                className="bg-blue-600 hover:bg-blue-700 text-white px-8 py-4 rounded-xl text-lg font-bold transition-all shadow-xl shadow-blue-200 active:scale-95"
              >
                {t.cta1}
              </button>
              <button className="bg-white border-2 border-gray-200 hover:border-gray-300 text-gray-700 px-8 py-4 rounded-xl text-lg font-bold transition-all active:scale-95">
                {t.cta2}
              </button>
            </div>
            <div className="mt-10 flex items-center space-x-6 text-sm text-gray-500 font-medium overflow-x-auto pb-2 whitespace-nowrap">
              <div className="flex items-center">
                <span className="w-2 h-2 bg-green-500 rounded-full mr-2"></span> {t.benefit1}
              </div>
              <div className="flex items-center">
                <span className="w-2 h-2 bg-green-500 rounded-full mr-2"></span> {t.benefit2}
              </div>
              <div className="flex items-center">
                <span className="w-2 h-2 bg-green-500 rounded-full mr-2"></span> {t.benefit3}
              </div>
            </div>
          </div>
          <div className="mt-16 lg:mt-0 relative flex justify-center lg:justify-end">
            <div className="relative w-72 h-[580px] bg-gray-900 rounded-[3rem] border-[8px] border-gray-800 shadow-2xl overflow-hidden transform rotate-3 hover:rotate-0 transition-transform duration-500">
               <div className="absolute top-0 w-full h-8 bg-gray-800 flex justify-center">
                 <div className="w-20 h-4 bg-gray-900 rounded-b-xl"></div>
               </div>
               <div className="p-6 pt-12 h-full bg-blue-600 text-white font-sans">
                  <div className="flex justify-between items-center mb-8">
                    <span className="text-xs opacity-80">9:41</span>
                    <div className="w-4 h-4 bg-white/20 rounded-full"></div>
                  </div>
                  <div className="mb-6">
                    <p className="text-xs opacity-80 mb-1">{t.mock.balance}</p>
                    <h3 className="text-3xl font-bold">$1,240.50</h3>
                  </div>
                  <div className="grid grid-cols-2 gap-3 mb-8">
                    <div className="bg-white/10 p-3 rounded-xl backdrop-blur-sm">
                      <p className="text-[10px] opacity-70">Digital Real</p>
                      <p className="font-semibold">R$ 450,00</p>
                    </div>
                    <div className="bg-white/10 p-3 rounded-xl backdrop-blur-sm">
                      <p className="text-[10px] opacity-70">Digital Euro</p>
                      <p className="font-semibold">€ 210,00</p>
                    </div>
                  </div>
                  <div className="bg-white rounded-3xl p-8 flex flex-col items-center justify-center text-gray-900 space-y-4">
                    <div className="w-16 h-16 bg-blue-100 rounded-2xl flex items-center justify-center">
                      <svg className="w-8 h-8 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z" /></svg>
                    </div>
                    <p className="font-bold text-center text-sm">{t.mock.scanner}</p>
                    <button className="w-full py-3 bg-blue-600 text-white rounded-xl text-xs font-bold">{t.mock.btn}</button>
                  </div>
               </div>
            </div>
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-blue-100 rounded-full blur-3xl -z-10 opacity-60"></div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
