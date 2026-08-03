const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

let serviceAccountString = process.env.FIREBASE_SERVICE_ACCOUNT;
if (!serviceAccountString) {
  console.error("FIREBASE_SERVICE_ACCOUNT env variable not found!");
  process.exit(1);
}

let serviceAccount;
try {
  serviceAccount = JSON.parse(serviceAccountString);
} catch (e) {
  serviceAccount = require(serviceAccountString);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const seedData = async () => {
  try {
    console.log('Seeding initial marketplace database...');

    // 1. Seed Service Categories
    const categories = [
      {
        id: 'cleaning',
        categoryName: 'Cleaning',
        categoryImageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800',
        description: 'Professional deep house cleaning services',
        subServices: ['Deep House Cleaning', 'Kitchen Cleaning', 'Bathroom Sanitization']
      },
      {
        id: 'plumbing',
        categoryName: 'Plumbing',
        categoryImageUrl: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=800',
        description: 'Expert leak repairs, fixture installations & drain cleaning',
        subServices: ['Leak Repair', 'Pipe Installation', 'Drain Cleaning']
      },
      {
        id: 'painting',
        categoryName: 'Painting',
        categoryImageUrl: 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=800',
        description: 'Premium interior & exterior wall painting services',
        subServices: ['Interior Painting', 'Exterior Painting', 'Wall Waterproofing']
      },
      {
        id: 'carwash',
        categoryName: 'Car Wash',
        categoryImageUrl: 'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?w=800',
        description: 'Eco-friendly premium car detailing at your doorstep',
        subServices: ['Exterior Wash & Wax', 'Interior Deep Detail', 'Full Body Polish']
      }
    ];

    for (const cat of categories) {
      await db.collection('services').doc(cat.id).set(cat);
      console.log(`Successfully seeded category: ${cat.categoryName}`);
    }

    // 2. Seed Hero Banners
    const banners = [
      {
        id: 'banner_1',
        image: 'assets/hero section img/image.png',
        title: 'Home Deep Cleaning',
        subtitle: 'Professional sanitization',
        discount: 'Flat 30% Off'
      },
      {
        id: 'banner_2',
        image: 'assets/hero section img/image copy.png',
        title: 'Expert Plumbing Solutions',
        subtitle: 'Fix leaks in minutes',
        discount: 'Starts at ₹99'
      },
      {
        id: 'banner_3',
        image: 'assets/hero section img/image copy 2.png',
        title: 'Premium Wall Painting',
        subtitle: 'Vibrant interior makeovers',
        discount: 'Free consultation'
      }
    ];

    for (const banner of banners) {
      await db.collection('banners').doc(banner.id).set(banner);
    }
    console.log('Seeded promotional banners.');

    console.log('Database seeding process completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Failed to seed database:', error);
    process.exit(1);
  }
};

seedData();
