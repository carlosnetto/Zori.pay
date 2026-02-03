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

export type Language = 'en' | 'es' | 'pt' | 'zh' | 'fr' | 'it';

export const languages = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'es', name: 'Español', flag: '🇪🇸' },
  { code: 'pt', name: 'Português', flag: '🇧🇷' },
  { code: 'zh', name: '中文', flag: '🇨🇳' },
  { code: 'fr', name: 'Français', flag: '🇫🇷' },
  { code: 'it', name: 'Italiano', flag: '🇮🇹' }
] as const;

export const translations = {
  en: {
    nav: { problem: 'Problem', solution: 'Solution', how: 'How it Works', faq: 'FAQ', about: 'About Us', cta: 'Get Zori', openAccount: 'Open Account', signin: 'Sign In', signout: 'Sign Out', myAccount: 'My Account' },
    hero: {
      title: 'Pay like a local. Anywhere.',
      subtitle: 'Hold digital currencies. Scan local QR codes. Pay instantly with your phone or smartglasses.',
      benefit1: 'Zero Cards Needed',
      benefit2: 'Near-FX Rates',
      benefit3: 'Smartglass Ready',
      cta1: 'Get Zori',
      cta2: 'How it works',
      mock: { balance: 'Total Balance', scanner: 'Scan local QR', btn: 'Pay Now' }
    },
    about: {
      label: 'Our Mission',
      title: 'Built for a world without borders',
      desc: 'Zori was born from a simple observation: the world is moving faster than banking systems. Travelers, digital nomads, and expats shouldn’t be penalized with fees just for moving between countries.',
      mission: 'Our mission is to make money as fluid as information. By leveraging secure digital currency infrastructure, we enable you to step into any shop, anywhere in the world, and pay just like someone who lives there.',
      vision: 'No plastic. No hidden spreads. Just instant local payments.'
    },
    problem: {
      label: 'The Problem',
      title: 'Paying abroad is always a mess',
      items: [
        'Cards charge high foreign transaction fees',
        'Traditional exchange rates are unfair',
        'Physical cards are often stolen or lost',
        'Local apps like Pix or UPI are restricted to residents',
        'You carry plastic while the world moves to QR'
      ],
      quote: '"There should be a better way."'
    },
    solution: {
      label: 'The Solution',
      title: 'Meet Zori',
      desc: 'The travel payment app that lets you pay like a local. No cards required. Use your phone or compatible smartglasses to bridge borders.',
      feat1: { t: 'Instant QR Scanning', d: 'Scan Pix, UPI, and local QR systems directly at any POS terminal.' },
      feat2: { t: 'Cross-Border Rails', d: 'Zori handles conversion instantly. The merchant receives normal local currency.' },
      feat3: { t: 'Privacy First', d: "Merchants never see your identity or card numbers—because there are none." },
      caption: 'Pure digital payments at any POS. No plastic required.',
      kast: "Visiting a country where QR Codes are not popular? Need a card? Download Kast app, have a card in your apple pay or google wallet and transfer funds directly from Zori to the card."
    },
    how: {
      label: 'Process',
      title: 'How Zori works',
      step1: { t: 'Hold digital currencies', d: 'Keep balances in Digital Dollars, Euros, and more. Powered by stablecoins.' },
      step2: { t: 'Convert instantly', d: 'Switch between currencies in seconds at near-FX rates.' },
      step3: { t: 'Scan and pay', d: 'Zori recognizes the QR and pays in local currency automatically via your device.' },
      noqr: { t: 'Future Ready: Smartglasses', d: 'Zori is built for the next generation of payments. Pay hands-free with compatible AR glasses.' }
    },
    faq: {
      title: 'Frequently Asked Questions',
      subtitle: 'Everything you need to know about Zori.',
      items: [
        { q: 'What is Zori?', a: 'Zori is a payment wallet that lets you pay any local QR system using your digital currencies.' },
        { q: 'Is it safe?', a: 'Yes, Zori uses institutional-grade security to protect your balances and transactions.' },
        { q: 'How do smartglasses work?', a: 'Compatible smartglasses use Zori Vision to recognize QR codes in your field of view for hands-free payment.' }
      ]
    },
    cta: { title: 'Money shouldn’t have borders', subtitle: 'Zori makes them disappear. Pay like a local today.', btn: 'Start with Zori' },
    footer: { mission: "Money shouldn't have borders. Zori makes them disappear.", rights: 'MTPSV SOCIEDADE PRESTADORA DE SERVICOS DE ATIVOS VIRTUAIS LTDA - CNPJ 64.687.332/0001-79', slogan: 'Built for a world without plastic cards.' },
    modal: { title: 'App available soon', desc: 'We are working hard to bring Zori to you. Stay tuned!', close: 'Close' },
    auth: {
      loginTitle: 'Welcome to Zori',
      loginDesc: 'Login or open your account to start paying like a local.',
      googleBtn: 'Continue with Google',
      simNew: 'Simulate New User',
      simExist: 'Simulate Existing User',
      passkeyTitle: 'Verify with Passkey',
      passkeyWait: 'Waiting for passkey...',
      passkeyRetry: 'Try Again',
      passkeyCancel: 'Cancel'
    },
    dashboard: {
      balance: 'Total Balance',
      send: 'Send',
      receive: 'Receive',
      convert: 'Convert',
      transactions: 'Recent Transactions',
      empty: 'No recent transactions.'
    },
    kyc: {
      title: 'Open your account',
      subtitle: 'Please provide your details to open a Zori account in Brazil.',
      country: 'Country of Residence',
      brazil: 'Brazil',
      fullName: 'Full Name',
      motherName: 'Mother\'s Full Name',
      cpf: 'CPF (Brazilian ID)',
      cpfErrorIncomplete: 'CPF must have 11 digits',
      cpfErrorInvalid: 'Invalid CPF',
      email: 'Email (Google-linked)',
      emailError: 'Invalid email address',
      phone: 'Mobile Phone',
      uploadTitle: 'Documents',
      idPdf: 'CNH (PDF)',
      or: 'OR',
      and: 'AND',
      idFront: 'CNH (Front)',
      idBack: 'CNH (Back)',
      selfie: 'Selfie holding CNH',
      proofAddr: 'Proof of Address (Utility Bill)',
      submit: 'Submit Application',
      successTitle: 'Application Received',
      successDesc: 'Your account is in the process of opening.',
      successNote: 'Stay tuned to your e-mail and cell phone and reply to the messages you receive. We will need some contracts digitally signed by gov.br which we will share with you shortly.',
      backHome: 'Back to Home'
    }
  },
  es: {
    nav: { problem: 'Problema', solution: 'Solución', how: 'Funcionamiento', faq: 'FAQ', about: 'Nosotros', cta: 'Obtener Zori', openAccount: 'Abrir Cuenta', signin: 'Entrar', signout: 'Cerrar Sesión', myAccount: 'Mi Cuenta' },
    hero: {
      title: 'Paga como un local. En cualquier lugar.',
      subtitle: 'Mantén monedas digitales. Escanea códigos QR locales. Paga al instante con tu móvil o gafas inteligentes.',
      benefit1: 'Sin tarjetas',
      benefit2: 'Tasas near-FX',
      benefit3: 'Gafas inteligentes',
      cta1: 'Obtener Zori',
      cta2: 'Cómo funciona',
      mock: { balance: 'Saldo Total', scanner: 'Escanear QR', btn: 'Pagar Ahora' }
    },
    about: {
      label: 'Nuestra Misión',
      title: 'Creado para un mundo sin fronteras',
      desc: 'Zori nació de una observación simple: el mundo se mueve más rápido que los sistemas bancarios. Los viajeros y nómadas digitales no deberían ser penalizados con comisiones solo por moverse entre países.',
      mission: 'Nuestra misión es hacer que el dinero sea tan fluido como la información. Al aprovechar la infraestructura de moneda digital segura, te permitimos entrar en cualquier tienda y pagar como un local.',
      vision: 'Sin plástico. Sin márgenes ocultos. Solo pagos locales instantâneos.'
    },
    problem: {
      label: 'El Problema',
      title: 'Pagar en el extranjero siempre es un lío',
      items: [
        'Las tarjetas cobran altas comisiones extranjeras',
        'Los tipos de cambio tradicionales no son justos',
        'Las tarjetas físicas se roban o se pierden',
        'Apps como Pix o UPI están restringidas',
        'Llevas plástico mientras el mundo usa QR'
      ],
      quote: '"Debería haber una mejor manera."'
    },
    solution: {
      label: 'La Solución',
      title: 'Conoce a Zori',
      desc: 'La app de pagos para viajes que te permite pagar como un local. Sin necesidad de tarjetas.',
      feat1: { t: 'Escaneo QR Instantáneo', d: 'Escanea códigos Pix, UPI y QRs locales directamente en cualquier terminal POS.' },
      feat2: { t: 'Conversión sin fisuras', d: 'Zori gestiona la conversión al instante. El comercio recibe moneda local.' },
      feat3: { t: 'Privacidad Total', d: 'Los comerciantes nunca ven tus datos bancarios ni de tarjeta.' },
      caption: 'Pagos digitales puros en cualquier POS. Sin plástico.',
      kast: "¿Visitas un país donde los códigos QR no son populares? ¿Necesitas una tarjeta? Descarga la app Kast, añade una tarjeta a Apple Pay o Google Wallet y transfiere fondos directamente desde Zori."
    },
    how: {
      label: 'Proceso',
      title: 'Cómo funciona Zori',
      step1: { t: 'Monedas digitales', d: 'Guarda Dólares, Euros digitales y más.' },
      step2: { t: 'Convierte al instante', d: 'Cambia entre monedas en segundos.' },
      step3: { t: 'Escanea y paga', d: 'Zori reconoce el QR y paga automáticamente.' },
      noqr: { t: 'Listo para el futuro', d: 'Paga sin manos con gafas de realidad aumentada compatibles.' }
    },
    faq: {
      title: 'Preguntas Frecuentes',
      subtitle: 'Todo lo que necesitas saber sobre Zori.',
      items: [
        { q: '¿Qué es Zori?', a: 'Zori es una billetera de pagos que te permite pagar en cualquier sistema QR local usando tus monedas digitales.' },
        { q: '¿Es seguro?', a: 'Sí, Zori utiliza seguridad de nivel institucional para proteger tus saldos y transacciones.' },
        { q: '¿Cómo funcionan las gafas inteligentes?', a: 'Las gafas compatibles usan Zori Vision para reconocer códigos QR en tu campo de visión y pagar sin usar las manos.' }
      ]
    },
    cta: { title: 'El dinero no debería tener fronteras', subtitle: 'Zori las hace desaparecer. Empieza a pagar como un local hoy.', btn: 'Empezar con Zori' },
    footer: { mission: 'Dinero sin fronteras. Zori las hace desaparecer.', rights: 'MTPSV SOCIEDADE PRESTADORA DE SERVICOS DE ATIVOS VIRTUAIS LTDA - CNPJ 64.687.332/0001-79', slogan: 'Creado para un mundo sin tarjetas de plástico.' },
    modal: { title: 'App disponible muy pronto', desc: 'Estamos trabajando duro para traerte Zori. ¡Mantente al tanto!', close: 'Cerrar' },
    auth: {
      loginTitle: 'Bienvenido a Zori',
      loginDesc: 'Inicia sesión o abre tu cuenta para comenzar a pagar como un local.',
      googleBtn: 'Continuar con Google',
      simNew: 'Simular Nuevo Usuario',
      simExist: 'Simular Usuario Existente',
      passkeyTitle: 'Verificar con Passkey',
      passkeyWait: 'Esperando passkey...',
      passkeyRetry: 'Intentar de nuevo',
      passkeyCancel: 'Cancelar'
    },
    dashboard: {
      balance: 'Saldo Total',
      send: 'Enviar',
      receive: 'Recibir',
      convert: 'Convertir',
      transactions: 'Transacciones Recientes',
      empty: 'No hay transacciones recientes.'
    },
    kyc: {
      title: 'Abre tu cuenta',
      subtitle: 'Por favor, proporciona tus datos para abrir una cuenta Zori en Brasil.',
      country: 'País de Residencia',
      brazil: 'Brasil',
      fullName: 'Nombre Completo',
      motherName: 'Nombre Completo de la Madre',
      cpf: 'CPF (ID Brasileño)',
      cpfErrorIncomplete: 'CPF debe tener 11 dígitos',
      cpfErrorInvalid: 'CPF inválido',
      email: 'Correo Electrónico (vinculado a Google)',
      emailError: 'Correo electrónico inválido',
      phone: 'Teléfono Móvil',
      uploadTitle: 'Documentos',
      idPdf: 'CNH (PDF)',
      or: 'O',
      and: 'Y',
      idFront: 'CNH (Frente)',
      idBack: 'CNH (Dorso)',
      selfie: 'Selfie sosteniendo CNH',
      proofAddr: 'Comprobante de Domicilio',
      submit: 'Enviar Solicitud',
      successTitle: 'Solicitud Recibida',
      successDesc: 'Tu cuenta está en proceso de apertura.',
      successNote: 'Mantente atento a tu correo electrónico y teléfono celular y responde a los mensajes que recibirás. Necesitaremos algunos contratos firmados digitalmente por gov.br que compartiremos contigo pronto.',
      backHome: 'Volver al Inicio'
    }
  },
  pt: {
    nav: { problem: 'Problema', solution: 'Solução', how: 'Como funciona', faq: 'FAQ', about: 'Sobre nós', cta: 'Baixar Zori', openAccount: 'Abrir Conta', signin: 'Entrar', signout: 'Sair', myAccount: 'Minha Conta' },
    hero: {
      title: 'Pague como um local. Em qualquer lugar.',
      subtitle: 'Mantenha moedas digitais. Escaneie QRs locais. Pague com seu celular ou óculos inteligentes.',
      benefit1: 'Zero Cartões',
      benefit2: 'Taxas near-FX',
      benefit3: 'Pronto para Óculos AR',
      cta1: 'Baixar Zori',
      cta2: 'Como funciona',
      mock: { balance: 'Saldo Total', scanner: 'Escanear QR', btn: 'Pagar Agora' }
    },
    about: {
      label: 'Nossa Missão',
      title: 'Feito para um mundo sem fronteiras',
      desc: 'O Zori nasceu de uma observação simples: o mundo se move mais rápido do que os sistemas bancários. Viajantes e nômades digitais não devem ser penalizados com taxas apenas por se deslocarem entre países.',
      mission: 'Nossa missão é tornar o dinheiro tão fluido quanto a informação. Usando infraestrutura digital segura, permitimos que você entre em qualquer loja e pague como se morasse lá.',
      vision: 'Sem plástico. Sem taxas escondidas. Apenas pagamentos locais instantâneos.'
    },
    problem: {
      label: 'O Problema',
      title: 'Pagar no exterior é sempre uma confusão',
      items: [
        'Cartões cobram taxas internacionais abusivas',
        'Taxas de câmbio tradicionais são injustas',
        'Cartões físicos são alvos de roubo',
        'Apps como Pix ou UPI são restritos a residentes',
        'Você usa plástico enquanto o mundo usa QR'
      ],
      quote: '"Deveria haver um jeito melhor."'
    },
    solution: {
      label: 'A Solução',
      title: 'Conheça o Zori',
      desc: 'O app que permite pagar como um local. Esqueça o plástico. Use seu smartphone ou óculos inteligentes.',
      feat1: { t: 'Leitura QR Instantânea', d: 'Escaneie códigos Pix, UPI e QRs locais diretamente em qualquer terminal POS.' },
      feat2: { t: 'Conversão na Hora', d: 'O Zori faz o câmbio instantaneamente para o lojista.' },
      feat3: { t: 'Privacidade Máxima', d: 'Seus dados de pagamento nunca são expostos ao lojista.' },
      caption: 'Pagamentos puramente digitais em qualquer POS. Sem necessidade de cartões.',
      kast: "Visitando um país onde QR Codes não são populares? Precisa de um cartão? Baixe o app Kast, tenha um cartão na sua Apple Pay ou Google Wallet e transfira fundos diretamente do Zori para o cartão."
    },
    how: {
      label: 'Processo',
      title: 'Como o Zori funciona',
      step1: { t: 'Moedas digitais', d: 'Saldos em Dólares, Euros e Reais Digitais.' },
      step2: { t: 'Converta na hora', d: 'Troque moedas em segundos com as melhores taxas.' },
      step3: { t: 'Escaneie e pague', d: 'O Zori reconhece o QR e paga em moeda local automaticamente.' },
      noqr: { t: 'Futuro: Óculos Inteligentes', d: 'O Zori está pronto para a próxima geração de pagamentos hands-free.' }
    },
    faq: {
      title: 'Perguntas Frequentes',
      subtitle: 'Tudo o que você precisa saber sobre o Zori.',
      items: [
        { q: 'O que é o Zori?', a: 'O Zori é uma carteira de pagamentos que permite pagar qualquer sistema QR local usando suas moedas digitais.' },
        { q: 'É seguro?', a: 'Sim, o Zori utiliza segurança de nível institucional para proteger seus saldos e transações.' },
        { q: 'Como funcionam os óculos inteligentes?', a: 'Óculos AR compatíveis usam o Zori Vision para reconhecer QRs no seu campo de visão e pagar sem as mãos.' }
      ]
    },
    cta: { title: 'Dinheiro não deve ter fronteiras', subtitle: 'Zori faz as fronteiras desaparecerem. Pague como um local.', btn: 'Começar com Zori' },
    footer: { mission: 'Dinheiro sem fronteiras. Zori as faz desaparecer.', rights: 'MTPSV SOCIEDADE PRESTADORA DE SERVICOS DE ATIVOS VIRTUAIS LTDA - CNPJ 64.687.332/0001-79', slogan: 'Feito para um mundo sem cartões de plástico.' },
    modal: { title: 'App disponível em breve', desc: 'Estamos trabalhando muito para trazer o Zori até você. Fique ligado!', close: 'Fechar' },
    auth: {
      loginTitle: 'Bem-vindo ao Zori',
      loginDesc: 'Faça login ou abra sua conta para começar a pagar como um local.',
      googleBtn: 'Continuar com Google',
      simNew: 'Simular Novo Usuário',
      simExist: 'Simular Usuário Existente',
      passkeyTitle: 'Verificar com Passkey',
      passkeyWait: 'Aguardando passkey...',
      passkeyRetry: 'Tentar novamente',
      passkeyCancel: 'Cancelar'
    },
    dashboard: {
      balance: 'Saldo Total',
      send: 'Enviar',
      receive: 'Receber',
      convert: 'Converter',
      transactions: 'Transações Recentes',
      empty: 'Nenhuma transação recente.'
    },
    kyc: {
      title: 'Abra sua conta',
      subtitle: 'Por favor, forneça seus dados para abrir uma conta Zori no Brasil.',
      country: 'País de Residência',
      brazil: 'Brasil',
      fullName: 'Nome Completo',
      motherName: 'Nome Completo da Mãe',
      cpf: 'CPF',
      cpfErrorIncomplete: 'CPF deve ter 11 dígitos',
      cpfErrorInvalid: 'CPF inválido',
      email: 'E-mail (vinculado ao Google)',
      emailError: 'E-mail inválido',
      phone: 'Celular',
      uploadTitle: 'Documentos',
      idPdf: 'CNH (PDF)',
      or: 'OU',
      and: 'E',
      idFront: 'CNH (Frente)',
      idBack: 'CNH (Verso)',
      selfie: 'Selfie segurando a CNH',
      proofAddr: 'Comprovante de Residência',
      submit: 'Enviar Solicitação',
      successTitle: 'Solicitação Recebida',
      successDesc: 'Sua conta está em processo de abertura.',
      successNote: 'Fique atento ao seu e-mail e celular e responda às mensagens que receber. Precisaremos de alguns contratos assinados digitalmente pelo gov.br que compartilharemos com você em breve.',
      backHome: 'Voltar ao Início'
    }
  },
  zh: {
    nav: { problem: '痛点', solution: '解决方案', how: '运作方式', faq: '常见问题', about: '关于我们', cta: '获取 Zori', openAccount: '开户', signin: '登录', signout: '退出登录', myAccount: '我的账户' },
    hero: {
      title: '像当地人一样支付。随处可用。',
      subtitle: '持有数字货币。扫描当地二维码。使用手机或智能眼镜即时支付。',
      benefit1: '无实体卡',
      benefit2: '实时汇率',
      benefit3: '适配智能眼镜',
      cta1: '获取 Zori',
      cta2: '运作方式',
      mock: { balance: '总余额', scanner: '扫描二维码', btn: '立即支付' }
    },
    about: {
      label: '我们的使命',
      title: '为无国界世界而建',
      desc: 'Zori 源于一个简单的观察：世界的发展速度超过了银行系统。旅行者、数字游民和外籍人士不应仅因跨国流动而被收取高额费用。',
      mission: '我们的使命是让金钱像信息一样自由流动。通过利用安全的数字货币基础设施，我们让您能走进世界上任何商店，像当地人一样支付。',
      vision: '告别塑料卡。拒绝隐形利差。纯粹的即时本地支付。'
    },
    problem: {
      label: '痛点',
      title: '海外支付总是一团糟',
      items: [
        '银行卡收取高额跨境交易手续费',
        '传统汇率非常不透明',
        '实体卡容易丢失或被盗',
        'Pix 或 UPI 等当地应用仅限居民使用',
        '当世界已进入二维码时代，你还在用塑料卡'
      ],
      quote: '“应该有更好的方式。”'
    },
    solution: {
      label: '解决方案',
      title: '了解 Zori',
      desc: '旅行支付应用，让您无需银行卡也能像当地人一样支付。支持手机和智能眼镜。',
      feat1: { t: '即时二维码扫描', d: '在任何 POS 终端直接扫描 Pix、UPI 和当地二维码。' },
      feat2: { t: '无缝货币转换', d: 'Zori 即时处理转换，商家接收当地货币。' },
      feat3: { t: '隐私保护', d: '商家永远无法获取您的身份或卡号信息。' },
      caption: '在任何 POS 终端进行纯数字支付，告别塑料银行卡。',
      kast: "前往二维码不普及的国家？需要银行卡？下载 Kast 应用，将卡片添加到 Apple Pay 或 Google Wallet，并直接从 Zori 转账到卡片。"
    },
    how: {
      label: '流程',
      title: 'Zori 如何运作',
      step1: { t: '持有数字货币', d: '持有美元、欧元等数字余额。' },
      step2: { t: '即时转换', d: '几秒钟内完成币种切换。' },
      step3: { t: '扫描支付', d: '自动识别二维码并完成本地支付。' },
      noqr: { t: '面向未来：智能眼镜', d: '支持兼容的 AR 眼镜，体验无需动手的支付方式。' }
    },
    faq: {
      title: '常见问题',
      subtitle: '关于 Zori 您需要了解的一切。',
      items: [
        { q: '什么是 Zori?', a: 'Zori 是一款支付钱包，让您可以使用数字货币支付任何当地二维码系统。' },
        { q: '它安全吗?', a: '是的，Zori 使用机构级安全技术来保护您的余额和交易。' },
        { q: '智能眼镜是如何工作的?', a: '兼容的智能眼镜使用 Zori Vision 识别您视野中的二维码，实现免提支付。' }
      ]
    },
    cta: { title: '金钱不应有国界', subtitle: 'Zori 让国界消失。今天就开始像当地人一样支付。', btn: '开始使用 Zori' },
    footer: { mission: '金钱不应有国界。Zori 让国界消失。', rights: 'MTPSV SOCIEDADE PRESTADORA DE SERVICOS DE ATIVOS VIRTUAIS LTDA - CNPJ 64.687.332/0001-79', slogan: '为告别塑料卡的世界而建。' },
    modal: { title: '应用即将推出', desc: '我们正在努力为您带来 Zori。敬请期待！', close: '关闭' },
    auth: {
      loginTitle: '欢迎来到 Zori',
      loginDesc: '登录或开户，开始像当地人一样支付。',
      googleBtn: '继续使用 Google',
      simNew: '模拟新用户',
      simExist: '模拟现有用户',
      passkeyTitle: '使用 Passkey 验证',
      passkeyWait: '等待 passkey...',
      passkeyRetry: '重试',
      passkeyCancel: '取消'
    },
    dashboard: {
      balance: '总余额',
      send: '发送',
      receive: '接收',
      convert: '兑换',
      transactions: '最近交易',
      empty: '暂无最近交易。'
    },
    kyc: {
      title: '开设您的账户',
      subtitle: '请提供您的详细信息以在巴西开设 Zori 账户。',
      country: '居住国',
      brazil: '巴西',
      fullName: '全名',
      motherName: '母亲全名',
      cpf: 'CPF (巴西身份证)',
      cpfErrorIncomplete: 'CPF 必须为 11 位数字',
      cpfErrorInvalid: 'CPF 无效',
      email: '电子邮件 (关联 Google)',
      emailError: '电子邮件无效',
      phone: '手机号码',
      uploadTitle: '证件上传',
      idPdf: 'CNH (PDF)',
      or: '或',
      and: '和',
      idFront: 'CNH (正面)',
      idBack: 'CNH (背面)',
      selfie: '手持 CNH 自拍',
      proofAddr: '地址证明 (水电费账单)',
      submit: '提交申请',
      successTitle: '申请已收到',
      successDesc: '您的账户正在开通中。',
      successNote: '请留意您的电子邮件和手机，并回复收到的消息。我们需要您通过 gov.br 进行一些合同的数字签名，稍后我们会分享给您。',
      backHome: '返回首页'
    }
  },
  fr: {
    nav: { problem: 'Problème', solution: 'Solution', how: 'Fonctionnement', faq: 'FAQ', about: 'À propos', cta: 'Obtenir Zori', openAccount: 'Ouvrir un Compte', signin: 'Se connecter', signout: 'Déconnexion', myAccount: 'Mon Compte' },
    hero: {
      title: 'Payez comme un local. Partout.',
      subtitle: 'Détenez des devises numériques. Scannez les codes QR locaux. Payez avec votre mobile ou vos lunettes.',
      benefit1: 'Zéro Carte',
      benefit2: 'Taux near-FX',
      benefit3: 'Smartglass Ready',
      cta1: 'Obtenir Zori',
      cta2: 'Comment ça marche',
      mock: { balance: 'Solde Total', scanner: 'Scannez QR', btn: 'Payer' }
    },
    about: {
      label: 'Notre Mission',
      title: 'Pour un monde sans frontières',
      desc: 'Zori est né d’un constat simple : le monde bouge plus vite que les banques. Les voyageurs et nomades digitaux ne devraient pas être pénalisés par des frais juste pour changer de pays.',
      mission: 'Notre mission est de rendre l’argent aussi fluide que l’information. Grâce à une infrastructure sécurisée, payez dans n’importe quelle boutique comme si vous y habitiez.',
      vision: 'Pas de plastique. Pas de frais cachés. Juste des paiements locaux instantanés.'
    },
    problem: {
      label: 'Le Problème',
      title: 'Payer à l’étranger est toujours un casse-tête',
      items: [
        'Les cartes facturent des frais exorbitants',
        'Les taux de change traditionnels sont injustes',
        'Les cartes physiques sont fragiles et volables',
        'Les apps locales sont réservées aux résidents',
        'Vous utilisez du plastique, le monde utilise des QR'
      ],
      quote: '"Il devrait y avoir une meilleure solution."'
    },
    solution: {
      label: 'La Solution',
      title: 'Découvrez Zori',
      desc: "L'application qui vous permet de payer comme un local, sans carte plastique. Utilisez votre smartphone ou vos lunettes connectées.",
      feat1: { t: 'Scan QR Instantané', d: 'Scannez Pix, UPI et codes QR directement sur n’importe quel terminal POS.' },
      feat2: { t: 'Conversion Fluide', d: 'Zori gère le change instantanément pour le marchand.' },
      feat3: { t: 'Anonymat Total', d: 'Aucun numéro de carte ne circule, car vous n’en avez pas besoin.' },
      caption: 'Paiements digitaux sur n’importe quel POS. Adieu le plastique.',
      kast: "Vous visitez un pays où les QR codes sont rares ? Besoin d'une carte ? Téléchargez l'app Kast, ajoutez une carte à Apple Pay ou Google Wallet et transférez des fonds directement depuis Zori."
    },
    how: {
      label: 'Processus',
      title: 'Comment Zori fonctionne',
      step1: { t: 'Digital Currencies', d: 'Soldes en Dollars et Euros numériques.' },
      step2: { t: 'Conversion', d: 'Changez de devise en quelques secondes.' },
      step3: { t: 'Scan & Pay', d: 'Zori reconnaît le QR et paie automatiquement.' },
      noqr: { t: 'Prêt pour le Futur', d: 'Payez sans les mains avec vos lunettes AR compatibles.' }
    },
    faq: {
      title: 'Foire Aux Questions',
      subtitle: 'Tout ce que vous devez savoir sur Zori.',
      items: [
        { q: 'Qu’est-ce que Zori?', a: 'Zori est un portefeuille de paiement qui vous permet de payer n’importe quel système QR local avec vos devises numériques.' },
        { q: 'Est-ce sécurisé?', a: 'Oui, Zori utilise une sécurité de niveau institutionnel pour protéger vos fonds.' },
        { q: 'Comment fonctionnent les lunettes?', a: 'Les lunettes compatibles utilisent Zori Vision pour identifier les QR codes et payer en mode mains libres.' }
      ]
    },
    cta: { title: "L'argent ne devrait pas avoir de frontières", subtitle: 'Zori les efface. Payez comme un local dès aujourd’hui.', btn: 'Lancer Zori' },
    footer: { mission: "L'argent n'a pas de frontières. Zori les efface.", rights: 'MTPSV SOCIEDADE PRESTADORA DE SERVICOS DE ATIVOS VIRTUAIS LTDA - CNPJ 64.687.332/0001-79', slogan: 'Conçu pour un monde sans cartes plastiques.' },
    modal: { title: 'App bientôt disponible', desc: 'Nous travaillons dur pour vous apporter Zori. Restez à l\'écoute !', close: 'Fermer' },
    auth: {
      loginTitle: 'Bienvenue chez Zori',
      loginDesc: 'Connectez-vous ou ouvrez un compte pour payer comme un local.',
      googleBtn: 'Continuer avec Google',
      simNew: 'Simuler Nouvel Utilisateur',
      simExist: 'Simuler Utilisateur Existant',
      passkeyTitle: 'Vérifier avec Passkey',
      passkeyWait: 'En attente de passkey...',
      passkeyRetry: 'Réessayer',
      passkeyCancel: 'Annuler'
    },
    dashboard: {
      balance: 'Solde Total',
      send: 'Envoyer',
      receive: 'Recevoir',
      convert: 'Convertir',
      transactions: 'Transactions Récentes',
      empty: 'Aucune transaction récente.'
    },
    kyc: {
      title: 'Ouvrez votre compte',
      subtitle: 'Veuillez fournir vos informations pour ouvrir un compte Zori au Brésil.',
      country: 'Pays de Résidence',
      brazil: 'Brésil',
      fullName: 'Nom Complet',
      motherName: 'Nom Complet de la Mère',
      cpf: 'CPF (ID Brésilien)',
      cpfErrorIncomplete: 'Le CPF doit comporter 11 chiffres',
      cpfErrorInvalid: 'CPF invalide',
      email: 'Email (lié à Google)',
      emailError: 'Email invalide',
      phone: 'Téléphone Mobile',
      uploadTitle: 'Documents',
      idPdf: 'CNH (PDF)',
      or: 'OU',
      and: 'ET',
      idFront: 'CNH (Recto)',
      idBack: 'CNH (Verso)',
      selfie: 'Selfie tenant CNH',
      proofAddr: 'Justificatif de Domicile',
      submit: 'Soumettre la demande',
      successTitle: 'Demande Reçue',
      successDesc: 'Votre compte est en cours d\'ouverture.',
      successNote: 'Surveillez votre e-mail et votre téléphone et répondez aux messages. Nous aurons besoin de contrats signés numériquement via gov.br que nous partagerons bientôt.',
      backHome: 'Retour à l\'Accueil'
    }
  },
  it: {
    nav: { problem: 'Problema', solution: 'Soluzione', how: 'Funzionamento', faq: 'FAQ', about: 'Chi siamo', cta: 'Ottieni Zori', openAccount: 'Apri un Conto', signin: 'Accedi', signout: 'Esci', myAccount: 'Il Mio Account' },
    hero: {
      title: 'Paga come un locale. Ovunque.',
      subtitle: 'Detieni valute digitali. Scansiona i codici QR locali. Paga con smartphone o occhiali smart.',
      benefit1: 'Zero Carte',
      benefit2: 'Tassi near-FX',
      benefit3: 'Smartglass Ready',
      cta1: 'Ottieni Zori',
      cta2: 'Come funziona',
      mock: { balance: 'Saldo Totale', scanner: 'Scansiona QR', btn: 'Paga' }
    },
    about: {
      label: 'La Nostra Missione',
      title: 'Creato per un mondo senza confini',
      desc: 'Zori nasce da un’osservazione semplice: il mondo si muove più velocemente delle banche. Viaggiatori e nomadi digitali non dovrebbero pagare commissioni solo per spostarsi.',
      mission: 'La nostra missione è rendere il denaro fluido come l’informazione. Grazie a un’infrastruttura sicura, ti permettiamo di pagare in qualsiasi negozio come un locale.',
      vision: 'Niente plastica. Niente spread nascosti. Solo pagamenti locali istantanei.'
    },
    problem: {
      label: 'Il Problema',
      title: 'Pagare all’estero è sempre un pasticcio',
      items: [
        'Le carte caricano commissioni estere elevate',
        'I tassi di cambio bancari sono ingiusti',
        'Le carte fisiche vengono spesso rubate',
        'App come Pix o UPI sono solo per residenti',
        'Usi la plastica mentre il mondo usa i QR'
      ],
      quote: '"Ci dovrebbe essere un modo migliore."'
    },
    solution: {
      label: 'La Soluzione',
      title: 'Incontra Zori',
      desc: "L'app che ti permette di pagare come un locale senza carte di credito. Usa il tuo smartphone o occhiali AR.",
      feat1: { t: 'Scansione QR Istantanea', d: 'Scansiona Pix, UPI e codici locali su qualsiasi terminale POS.' },
      feat2: { t: 'Cambio Istantaneo', d: 'Zori gestisce la conversione valuta sul momento.' },
      feat3: { t: 'Privacy Totale', d: 'I mercanti non vedranno mai i tuoi dati bancari.' },
      caption: 'Pagamenti digitali su qualsiasi POS. Niente plastica.',
      kast: "Visiti un paese dove i codici QR non sono popolari? Ti serve una carta? Scarica l'app Kast, aggiungi una carta su Apple Pay o Google Wallet e trasferisci fondi direttamente da Zori."
    },
    how: {
      label: 'Processo',
      title: 'Come funziona Zori',
      step1: { t: 'Valute Digitali', d: 'Saldo in Dollari ed Euro digitali.' },
      step2: { t: 'Converti subito', d: 'Cambia valuta in pochi secondi.' },
      step3: { t: 'Scansiona e paga', d: 'Zori riconosce il QR e paga automaticamente.' },
      noqr: { t: 'Pronti per il futuro', d: 'Paga a mani libere con gli occhiali AR compatibili.' }
    },
    faq: {
      title: 'Domande Frequenti',
      subtitle: 'Tutto quello che c’è da sapere su Zori.',
      items: [
        { q: 'Cos’è Zori?', a: 'Zori è un portafoglio che ti permette di pagare su qualsiasi sistema QR locale usando valute digitali.' },
        { q: 'È sicuro?', a: 'Sì, Zori usa sicurezza di grado istituzionale per proteggere saldi e transazioni.' },
        { q: 'Come funzionano gli occhiali?', a: 'Gli occhiali AR compatibili usano Zori Vision per riconoscere i QR nel tuo campo visivo e pagare senza mani.' }
      ]
    },
    cta: { title: 'Il denaro non dovrebbe avere confini', subtitle: 'Zori li fa sparire. Inizia a pagare come un locale oggi.', btn: 'Inizia con Zori' },
    footer: { mission: 'Soldi senza confini. Zori li cancella.', rights: 'MTPSV SOCIEDADE PRESTADORA DE SERVICOS DE ATIVOS VIRTUAIS LTDA - CNPJ 64.687.332/0001-79', slogan: 'Creato per un mondo senza carte di plastica.' },
    modal: { title: 'App disponibile a breve', desc: 'Stiamo lavorando sodo per portarti Zori. Rimanete sintonizzati!', close: 'Chiudi' },
    auth: {
      loginTitle: 'Benvenuto in Zori',
      loginDesc: 'Accedi o apri il tuo account per iniziare a pagare come un locale.',
      googleBtn: 'Continua con Google',
      simNew: 'Simula Nuovo Utente',
      simExist: 'Simula Utente Esistente',
      passkeyTitle: 'Verifica con Passkey',
      passkeyWait: 'In attesa di passkey...',
      passkeyRetry: 'Riprova',
      passkeyCancel: 'Annulla'
    },
    dashboard: {
      balance: 'Saldo Totale',
      send: 'Invia',
      receive: 'Ricevi',
      convert: 'Converti',
      transactions: 'Transazioni Recenti',
      empty: 'Nessuna transazione recente.'
    },
    kyc: {
      title: 'Apri il tuo conto',
      subtitle: 'Fornisci i tuoi dati per aprire un conto Zori in Brasile.',
      country: 'Paese di Residenza',
      brazil: 'Brasile',
      fullName: 'Nome Completo',
      motherName: 'Nome Completo della Madre',
      cpf: 'CPF',
      cpfErrorIncomplete: 'Il CPF deve avere 11 cifre',
      cpfErrorInvalid: 'CPF non valido',
      email: 'Email (collegata a Google)',
      emailError: 'Email non valida',
      phone: 'Cellulare',
      uploadTitle: 'Documenti',
      idPdf: 'CNH (PDF)',
      or: 'OPPURE',
      and: 'E',
      idFront: 'CNH (Fronte)',
      idBack: 'CNH (Retro)',
      selfie: 'Selfie con CNH',
      proofAddr: 'Prova di Indirizzo',
      submit: 'Invia Richiesta',
      successTitle: 'Richiesta Ricevuta',
      successDesc: 'Il tuo account è in fase di apertura.',
      successNote: 'Tieni d\'occhio la tua e-mail e il cellulare e rispondi ai messaggi che riceverai. Avremo bisogno di alcuni contratti firmati digitalmente da gov.br che condivideremo con te a breve.',
      backHome: 'Torna alla Home'
    }
  }
};
