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

interface HowItWorksProps {
  currentLang: Language;
}

const HowItWorks: React.FC<HowItWorksProps> = ({ currentLang }) => {
  const t = translations[currentLang].how;

  const steps = [
    { id: 1, ...t.step1, color: "bg-blue-100 text-blue-600" },
    { id: 2, ...t.step2, color: "bg-purple-100 text-purple-600" },
    { id: 3, ...t.step3, color: "bg-green-100 text-green-600" },
  ];

  return (
    <section id="how-it-works" className="py-24 bg-gray-50 scroll-mt-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-sm font-bold text-purple-600 uppercase tracking-widest mb-4">{t.label}</h2>
          <h3 className="text-4xl md:text-5xl font-extrabold text-gray-900">{t.title}</h3>
        </div>
        <div className="grid md:grid-cols-3 gap-12">
          {steps.map((step) => (
            <div key={step.id} className="relative bg-white p-10 rounded-3xl shadow-lg hover:shadow-xl transition-shadow border border-gray-100 group">
              <div className={`w-16 h-16 rounded-2xl ${step.color} flex items-center justify-center text-2xl font-black mb-8 group-hover:scale-110 transition-transform`}>
                {step.id}
              </div>
              <h4 className="text-2xl font-bold mb-4">{step.t}</h4>
              <p className="text-gray-600 leading-relaxed">{step.d}</p>
              {step.id < 3 && (
                 <div className="hidden lg:block absolute top-1/2 -right-6 transform -translate-y-1/2 text-gray-200">
                    <svg className="w-12 h-12" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
                 </div>
              )}
            </div>
          ))}
        </div>

        <div className="mt-24 bg-gradient-to-r from-stone-800 to-stone-900 rounded-3xl p-8 lg:p-16 text-white shadow-2xl relative overflow-hidden">
           <div className="absolute top-0 right-0 p-4 opacity-10">
              <svg className="w-64 h-64" fill="currentColor" viewBox="0 0 24 24">
                <path d="M21 9H3V7h18v2zM3 11v6c0 1.1.9 2 2 2h4c1.1 0 2-.9 2-2v-6H3zm18 0v6c0 1.1-.9 2-2 2h-4c-1.1 0-2-.9-2-2v-6h8z" />
              </svg>
           </div>
           <div className="relative z-10 max-w-3xl">
             <h4 className="text-3xl font-bold mb-6">{t.noqr.t}</h4>
             <p className="text-xl opacity-90 leading-relaxed mb-8">
               {t.noqr.d}
             </p>
             <div className="flex flex-wrap gap-4 items-center">
               <span className="bg-white/10 px-4 py-2 rounded-lg text-sm font-medium">Wearable Ready</span>
               <span className="bg-white/10 px-4 py-2 rounded-lg text-sm font-medium">NFC & QR Optical Pay</span>
               <span className="bg-blue-500/20 text-blue-300 px-4 py-2 rounded-lg text-sm font-bold border border-blue-500/30">Beta Program Open</span>
             </div>
           </div>
        </div>
      </div>
    </section>
  );
};

export default HowItWorks;
