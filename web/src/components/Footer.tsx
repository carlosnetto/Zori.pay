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

interface FooterProps {
  currentLang: Language;
}

const Footer: React.FC<FooterProps> = ({ currentLang }) => {
  const t = translations[currentLang].footer;
  const nav = translations[currentLang].nav;

  const handlePlaceholderClick = (e: React.MouseEvent) => {
    e.preventDefault();
  };

  return (
    <footer className="bg-gray-50 border-t border-gray-200 pt-16 pb-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid md:grid-cols-4 gap-12 mb-12">
          <div className="col-span-2">
            <div className="flex items-center space-x-2 mb-6">
              <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-xl">Z</span>
              </div>
              <span className="text-2xl font-extrabold tracking-tight text-blue-600">zori.pay</span>
            </div>
            <p className="text-gray-500 max-w-sm mb-6">
              {t.mission}
            </p>
          </div>
          <div>
            <h4 className="font-bold mb-4">{nav.solution}</h4>
            <ul className="space-y-2 text-gray-500 text-sm">
              <li><a href="#" onClick={handlePlaceholderClick} className="hover:text-blue-600 transition-colors">App Store</a></li>
              <li><a href="#" onClick={handlePlaceholderClick} className="hover:text-blue-600 transition-colors">Google Play</a></li>
              <li><a href="#" onClick={handlePlaceholderClick} className="hover:text-blue-600 transition-colors">Security</a></li>
            </ul>
          </div>
          <div>
            <h4 className="font-bold mb-4">Legal</h4>
            <ul className="space-y-2 text-gray-500 text-sm">
              <li><a href="#" onClick={handlePlaceholderClick} className="hover:text-blue-600 transition-colors">Privacy</a></li>
              <li><a href="#" onClick={handlePlaceholderClick} className="hover:text-blue-600 transition-colors">Terms</a></li>
            </ul>
          </div>
        </div>
        <div className="border-t border-gray-200 pt-8 flex flex-col md:flex-row justify-between items-center text-xs text-gray-400">
          <p>{t.rights}</p>
          <p>{t.slogan}</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
