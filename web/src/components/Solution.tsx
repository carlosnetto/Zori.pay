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

interface SolutionProps {
  currentLang: Language;
}

const Solution: React.FC<SolutionProps> = ({ currentLang }) => {
  const t = translations[currentLang].solution;

  return (
    <section id="solution" className="py-24 bg-white relative overflow-hidden scroll-mt-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="lg:grid lg:grid-cols-2 lg:gap-16 items-center">
          <div className="order-2 lg:order-1 mt-12 lg:mt-0">
            <div className="relative rounded-3xl overflow-hidden shadow-2xl group">
              {/* Updated image: Focused solely on QR scanning action, no cards visible */}
              <img
                src="/images/Gemini_Generated_Image_rehqahrehqahrehq.png"
                alt="Scanning a merchant QR code with a smartphone"
                className="w-full object-cover aspect-video lg:aspect-square group-hover:scale-105 transition-transform duration-700"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent flex items-end p-8">
                <div>
                  <div className="bg-green-500 text-white text-xs font-bold px-2 py-1 rounded-md inline-block mb-2 uppercase tracking-wide">
                    No Hardware Needed
                  </div>
                  <p className="text-white text-xl font-medium leading-snug">{t.caption}</p>
                </div>
              </div>
            </div>
          </div>
          <div className="order-1 lg:order-2">
            <h2 className="text-sm font-bold text-green-600 uppercase tracking-widest mb-4">{t.label}</h2>
            <h3 className="text-4xl md:text-5xl font-extrabold text-gray-900 mb-8 italic">{t.title}</h3>
            <p className="text-xl text-gray-600 mb-6 leading-relaxed">
              {t.desc}
            </p>
            <ul className="space-y-6">
              {[t.feat1, t.feat2, t.feat3].map((feat, i) => (
                <li key={i} className="flex items-start">
                  <div className="flex-shrink-0 w-10 h-10 bg-green-100 rounded-full flex items-center justify-center mr-4">
                    <svg className="w-6 h-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" /></svg>
                  </div>
                  <div>
                    <h4 className="text-lg font-bold">{feat.t}</h4>
                    <p className="text-gray-600">{feat.d}</p>
                  </div>
                </li>
              ))}
            </ul>

            {/* Kast Promotion Section */}
            <div className="mt-8 pt-8 border-t border-gray-100">
              <div className="bg-gray-50 border border-gray-200 rounded-xl p-5 flex items-start space-x-4">
                <div className="flex-shrink-0">
                  <div className="w-10 h-10 bg-gray-900 rounded-lg flex items-center justify-center text-white font-bold text-xl">K</div>
                </div>
                <div>
                  <p className="text-gray-800 text-sm font-medium leading-relaxed">
                    {t.kast}
                  </p>
                </div>
              </div>
            </div>

          </div>
        </div>
      </div>
    </section>
  );
};

export default Solution;
