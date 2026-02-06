export const SITE = {
  name: "Verbio",
  tagline: "AI Voice Translation",
  description:
    "Break language barriers instantly. Verbio translates your voice in real time with natural AI-powered speech across 50+ languages.",
  url: "https://verbio.app",
  appStoreUrl:
    "https://apps.apple.com/app/verbio-ai-voice-translator/id6741234567",
  supportEmail: "support@verbio.app",
  legalEmail: "legal@verbio.app",
  privacyEmail: "privacy@verbio.app",
  companyName: "Verbio Technologies, Inc.",
  companyAddress: "548 Market Street, Suite 36879, San Francisco, CA 94104",
  socialLinks: {
    twitter: "https://x.com/verbioapp",
    instagram: "https://instagram.com/verbioapp",
    tiktok: "https://tiktok.com/@verbioapp",
  },
} as const;

export const PLANS = [
  {
    name: "Free",
    tier: "free" as const,
    monthlyPrice: 0,
    yearlyPrice: 0,
    description: "Get started with basic translation",
    features: [
      { text: "10 translations per day", included: true },
      { text: "10 minutes per month", included: true },
      { text: "Basic voices", included: true },
      { text: "Conversation mode", included: false },
      { text: "Phrase saving", included: false },
      { text: "Premium voices", included: false },
      { text: "Offline mode", included: false },
      { text: "Priority processing", included: false },
    ],
    cta: "Download Free",
    highlighted: false,
  },
  {
    name: "Pro",
    tier: "pro" as const,
    monthlyPrice: 4.99,
    yearlyPrice: 39.99,
    description: "For frequent travelers and communicators",
    badge: "Most Popular",
    features: [
      { text: "200 translations per day", included: true },
      { text: "300 minutes per month", included: true },
      { text: "Premium voices", included: true },
      { text: "Conversation mode", included: true },
      { text: "Phrase saving", included: true },
      { text: "Offline mode", included: false },
      { text: "Priority processing", included: false },
    ],
    cta: "Start Free Trial",
    highlighted: true,
  },
  {
    name: "Premium",
    tier: "premium" as const,
    monthlyPrice: 9.99,
    yearlyPrice: 79.99,
    description: "Unlimited power for professionals",
    badge: "Best Value",
    features: [
      { text: "Unlimited translations", included: true },
      { text: "Unlimited minutes", included: true },
      { text: "All voices", included: true },
      { text: "Conversation mode", included: true },
      { text: "Phrase saving", included: true },
      { text: "Offline mode", included: true },
      { text: "Priority processing", included: true },
    ],
    cta: "Start Free Trial",
    highlighted: false,
  },
] as const;

export const FEATURES = [
  {
    icon: "Globe" as const,
    title: "50+ Languages",
    description:
      "Translate between over 50 languages with dialect-level accuracy powered by state-of-the-art neural models.",
  },
  {
    icon: "Mic" as const,
    title: "Voice-First",
    description:
      "Speak naturally and hear your translation spoken back in lifelike AI voices that capture tone and nuance.",
  },
  {
    icon: "MessageSquare" as const,
    title: "Live Conversations",
    description:
      "Two-way real-time conversation mode translates for both speakers — just talk and Verbio handles the rest.",
  },
  {
    icon: "Bookmark" as const,
    title: "Save Phrases",
    description:
      "Build your personal phrasebook. Save translations you use most for instant access anytime, anywhere.",
  },
  {
    icon: "WifiOff" as const,
    title: "Offline Mode",
    description:
      "Download language packs and translate without an internet connection. Perfect for international travel.",
  },
  {
    icon: "Zap" as const,
    title: "Instant Results",
    description:
      "Sub-second translation latency with priority processing. No waiting, no buffering — just seamless speech.",
  },
] as const;

export const TESTIMONIALS = [
  {
    name: "Sarah Chen",
    role: "Travel Blogger",
    quote:
      "Verbio completely changed how I travel. I navigated Tokyo, Barcelona, and Istanbul having real conversations with locals. The voice quality is incredible.",
    rating: 5,
  },
  {
    name: "Marco Reyes",
    role: "International Sales Director",
    quote:
      "I close deals across Latin America and Europe. Verbio's conversation mode lets me build genuine rapport with clients in their native language.",
    rating: 5,
  },
  {
    name: "Dr. Amara Okafor",
    role: "Emergency Physician",
    quote:
      "In the ER, every second counts. Verbio helps me communicate with patients who speak different languages when professional interpreters aren't available.",
    rating: 5,
  },
] as const;

export const FAQS = [
  {
    question: "How accurate is Verbio's translation?",
    answer:
      "Verbio uses the latest neural machine translation models, delivering accuracy on par with professional human translators for most common languages and everyday conversation. We continuously improve our models with the latest AI research.",
  },
  {
    question: "What languages does Verbio support?",
    answer:
      "Verbio supports over 50 languages including Spanish, French, German, Mandarin Chinese, Japanese, Korean, Arabic, Portuguese, Italian, Hindi, and many more. We add new languages regularly.",
  },
  {
    question: "How does the free trial work?",
    answer:
      "Yearly Pro and Premium plans include a 7-day free trial. You won't be charged until the trial ends, and you can cancel anytime before then. Your subscription will automatically begin after the trial period unless cancelled.",
  },
  {
    question: "Can I use Verbio offline?",
    answer:
      "Yes! Premium subscribers can download language packs for offline use. This is perfect for traveling to areas with limited connectivity. Offline mode supports all major languages.",
  },
  {
    question: "How does conversation mode work?",
    answer:
      "Conversation mode enables real-time two-way translation. Simply set the two languages, tap to speak, and Verbio translates for both parties. It's like having a personal interpreter in your pocket.",
  },
  {
    question: "How do I cancel my subscription?",
    answer:
      "You can cancel anytime through your Apple ID subscription settings or directly within the Verbio app under Settings > Subscription > Manage Subscription. You'll retain access until the end of your current billing period.",
  },
] as const;
