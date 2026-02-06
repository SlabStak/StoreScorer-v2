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

// Clerk requires publishableKey - wrap conditionally for build compatibility
const hasClerkKey = !!process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY;

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const content = (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  );

  // Only wrap with ClerkProvider if the key is available
  if (hasClerkKey) {
    return <ClerkProvider>{content}</ClerkProvider>;
  }

  return content;
}
