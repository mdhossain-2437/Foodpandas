// Server-side copy of the sample stalls shown in the app (`vendors` in
// lib/main.dart). Prices here are authoritative for sandbox checkout and for
// grounding the AI menu assistant.
const demoMenu = {
  'demo-tita-luz': {
    name: 'Demo Tita Luz’s Kusina',
    category: 'Filipino',
    deliveryFee: 49,
    items: {
      adobo: {
        name: 'Chicken Adobo',
        price: 165,
        description: 'Soy-vinegar braised chicken, garlic rice & atchara.',
      },
      sinigang: {
        name: 'Sinigang na Baboy',
        price: 195,
        description: 'Tamarind-sour pork soup with fresh kangkong.',
      },
      sisig: {
        name: 'Sizzling Pork Sisig',
        price: 185,
        description: 'Crispy, tangy sisig with calamansi on the side.',
      },
    },
  },
  'demo-mang-tonyo': {
    name: 'Demo Mang Tonyo’s Ihaw-Ihaw',
    category: 'Grill',
    deliveryFee: 49,
    items: {
      bbq: {
        name: 'Pork BBQ Meal',
        price: 145,
        description: 'Two sweet-savory skewers, java rice & toyomansi.',
      },
      liempo: {
        name: 'Inihaw na Liempo',
        price: 210,
        description: 'Smoky grilled pork belly with ensaladang talong.',
      },
      isaw: {
        name: 'Isaw & Betamax Combo',
        price: 99,
        description: 'Street-side classics with spicy suka dip.',
      },
    },
  },
  'demo-ate-mels': {
    name: 'Demo Ate Mel’s Meryenda',
    category: 'Meryenda',
    deliveryFee: 49,
    items: {
      'halo-halo': {
        name: 'Special Halo-Halo',
        price: 120,
        description: 'Shaved ice, leche flan, ube & all the good stuff.',
      },
      turon: {
        name: 'Banana Turon (3 pcs)',
        price: 75,
        description: 'Crispy saba rolls with a caramelized sugar coat.',
      },
      pancit: {
        name: 'Pancit Palabok',
        price: 135,
        description: 'Noodles in rich shrimp sauce, topped with chicharon.',
      },
    },
  },
  'demo-lola-bebang': {
    name: 'Demo Lola Bebang’s Panaderya',
    category: 'Bakery',
    deliveryFee: 49,
    items: {
      pandesal: {
        name: 'Pandesal (6 pcs)',
        price: 45,
        description: 'Warm, soft pandesal rolled in toasted breadcrumbs.',
      },
      ensaymada: {
        name: 'Classic Ensaymada',
        price: 65,
        description: 'Buttery brioche, whipped butter & grated cheese.',
      },
      'ube-cheese': {
        name: 'Ube Cheese Pandesal (4 pcs)',
        price: 88,
        description: 'Soft ube bread with a creamy cheese center.',
      },
    },
  },
};

module.exports = { demoMenu };
