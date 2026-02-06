import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import { SITE } from "@/lib/constants";
import Header from "@/components/layout/Header";
import Footer from "@/components/layout/Footer";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  display: "swap",
  variable: "--font-inter",
});

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#FFFEF7" },
    { media: "(prefers-color-scheme: dark)", color: "#000000" },
  ],
};

export const metadata: Metadata = {
  metadataBase: new URL(SITE.url),
  title: {
    default: `${SITE.name} — AI Voice Translation for 50+ Languages`,
    template: `%s | ${SITE.name}`,
  },
  description: SITE.description,
  keywords: [
    "voice translation",
    "AI translator",
    "real-time translation",
    "language translator app",
    "speech translation",
    "conversation translator",
    "travel translator",
    "offline translator",
    "voice to voice translation",
    "AI voice translation app",
    "multilingual translator",
    "live translation app",
  ],
  authors: [{ name: SITE.companyName }],
  creator: SITE.companyName,
  publisher: SITE.companyName,
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  openGraph: {
    type: "website",
    locale: "en_US",
    url: SITE.url,
    siteName: SITE.name,
    title: `${SITE.name} — AI Voice Translation for 50+ Languages`,
    description: SITE.description,
    images: [
      {
        url: "/og.png",
        width: 1200,
        height: 630,
        alt: `${SITE.name} — Speak the world's languages`,
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: `${SITE.name} — AI Voice Translation`,
    description: SITE.description,
    creator: "@verbioapp",
    images: ["/og.png"],
  },
  alternates: {
    canonical: SITE.url,
  },
  category: "technology",
  appLinks: {
    ios: {
      url: SITE.appStoreUrl,
      app_store_id: "6741234567",
    },
  },
  itunes: {
    appId: "6741234567",
    appArgument: SITE.url,
  },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": `${SITE.url}/#organization`,
      name: SITE.companyName,
      url: SITE.url,
      logo: `${SITE.url}/logo.png`,
      sameAs: Object.values(SITE.socialLinks),
    },
    {
      "@type": "WebSite",
      "@id": `${SITE.url}/#website`,
      url: SITE.url,
      name: SITE.name,
      publisher: { "@id": `${SITE.url}/#organization` },
    },
    {
      "@type": "SoftwareApplication",
      name: SITE.name,
      operatingSystem: "iOS",
      applicationCategory: "UtilitiesApplication",
      offers: [
        {
          "@type": "Offer",
          price: "0",
          priceCurrency: "USD",
          name: "Free",
        },
        {
          "@type": "Offer",
          price: "4.99",
          priceCurrency: "USD",
          name: "Pro Monthly",
          billingDuration: "P1M",
        },
        {
          "@type": "Offer",
          price: "39.99",
          priceCurrency: "USD",
          name: "Pro Yearly",
          billingDuration: "P1Y",
        },
        {
          "@type": "Offer",
          price: "9.99",
          priceCurrency: "USD",
          name: "Premium Monthly",
          billingDuration: "P1M",
        },
        {
          "@type": "Offer",
          price: "79.99",
          priceCurrency: "USD",
          name: "Premium Yearly",
          billingDuration: "P1Y",
        },
      ],
      aggregateRating: {
        "@type": "AggregateRating",
        ratingValue: "4.9",
        ratingCount: "12847",
        bestRating: "5",
      },
      description: SITE.description,
    },
  ],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={inter.variable}>
      <head>
        <link rel="icon" href="/favicon.ico" sizes="any" />
        <link rel="icon" href="/icon.svg" type="image/svg+xml" />
        <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
        <link rel="manifest" href="/manifest.webmanifest" />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body className="font-sans antialiased">
        <Header />
        <main>{children}</main>
        <Footer />
      </body>
    </html>
  );
}
