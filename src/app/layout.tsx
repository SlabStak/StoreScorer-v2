import type { Metadata } from 'next';
import { ClerkProvider } from '@clerk/nextjs';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'StoreScorer - AI-Powered E-Commerce Store Audit',
  description:
    'Get an AI-powered audit of your e-commerce store with actionable recommendations to improve conversions.',
  keywords: ['e-commerce', 'store audit', 'shopify', 'conversion optimization', 'AI'],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body className={inter.className}>{children}</body>
      </html>
    </ClerkProvider>
  );
}
