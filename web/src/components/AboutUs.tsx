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

interface AboutUsProps {
  currentLang: Language;
}

const AboutUs: React.FC<AboutUsProps> = ({ currentLang }) => {
  const t = translations[currentLang].about;

  return (
    <section id="about" className="py-24 bg-white border-t border-gray-100 overflow-hidden scroll-mt-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="lg:grid lg:grid-cols-2 lg:gap-16 items-center">
          <div>
            <h2 className="text-sm font-bold text-blue-600 uppercase tracking-widest mb-4">{t.label}</h2>
            <h3 className="text-4xl md:text-5xl font-extrabold text-gray-900 mb-8 leading-tight">
              {t.title}
            </h3>
            <div className="space-y-6 text-lg text-gray-600 leading-relaxed">
              <p>{t.desc}</p>
              <p className="font-medium text-gray-900 border-l-4 border-blue-600 pl-6 py-2 bg-blue-50 rounded-r-xl italic">
                {t.mission}
              </p>
              <p className="font-bold text-blue-600">{t.vision}</p>
            </div>
          </div>
          <div className="mt-12 lg:mt-0 relative">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-4 pt-12">
                <img 
                  src="https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&q=80&w=400" 
                  alt="Team collaboration" 
                  className="rounded-2xl shadow-lg aspect-square object-cover" 
                />
                <img 
                  src="https://images.unsplash.com/photo-1551434678-e076c223a692?auto=format&fit=crop&q=80&w=400" 
                  alt="Office setup" 
                  className="rounded-2xl shadow-lg aspect-[3/4] object-cover" 
                />
              </div>
              <div className="space-y-4">
                <img 
                  src="https://images.unsplash.com/photo-1499750310107-5fef28a66643?auto=format&fit=crop&q=80&w=400" 
                  alt="Digital nomad working" 
                  className="rounded-2xl shadow-lg aspect-[3/4] object-cover" 
                />
                <img 
                  src="https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&q=80&w=400" 
                  alt="Modern tech" 
                  className="rounded-2xl shadow-lg aspect-square object-cover" 
                />
              </div>
            </div>
            <div className="absolute -z-10 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-full bg-blue-50 rounded-full blur-3xl opacity-50"></div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default AboutUs;
