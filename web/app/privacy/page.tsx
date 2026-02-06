import type { Metadata } from "next";
import LegalLayout from "@/components/legal/LegalLayout";
import { SITE } from "@/lib/constants";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description: `Privacy Policy for the ${SITE.name} application and services.`,
  alternates: { canonical: `${SITE.url}/privacy` },
};

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "WebPage",
  name: `Privacy Policy — ${SITE.name}`,
  url: `${SITE.url}/privacy`,
  breadcrumb: {
    "@type": "BreadcrumbList",
    itemListElement: [
      {
        "@type": "ListItem",
        position: 1,
        name: "Home",
        item: SITE.url,
      },
      {
        "@type": "ListItem",
        position: 2,
        name: "Privacy Policy",
        item: `${SITE.url}/privacy`,
      },
    ],
  },
};

export default function PrivacyPolicy() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <LegalLayout title="Privacy Policy" lastUpdated="February 5, 2026">
        <p>
          {SITE.companyName} (&quot;Verbio,&quot; &quot;we,&quot;
          &quot;us,&quot; or &quot;our&quot;) is committed to protecting your
          privacy. This Privacy Policy explains how we collect, use, disclose,
          and safeguard your information when you use our mobile application
          (&quot;App&quot;), website at{" "}
          <a href={SITE.url}>{SITE.url}</a> (&quot;Website&quot;), and
          related services (collectively, the &quot;Service&quot;).
        </p>
        <p>
          Please read this Privacy Policy carefully. By using the Service, you
          consent to the practices described in this policy. If you do not
          agree with this policy, please do not use the Service.
        </p>

        <h2 id="information-collected">1. Information We Collect</h2>

        <h3>1.1 Information You Provide</h3>
        <ul>
          <li>
            <strong>Account Information:</strong> When you create an account
            using Sign in with Apple, we receive your Apple User ID, email
            address (which may be a private relay address), and optionally your
            name. We do not receive or store your Apple ID password.
          </li>
          <li>
            <strong>Audio Data:</strong> When you use the translation feature,
            we process your voice recordings to perform speech-to-text
            conversion and translation. Audio recordings are processed in real
            time and are <strong>not permanently stored</strong> on our servers
            after the translation is complete.
          </li>
          <li>
            <strong>Saved Phrases:</strong> If you choose to save translations
            to your phrase library, the source text, translated text, and
            associated language information are stored securely in association
            with your account.
          </li>
          <li>
            <strong>Conversation History:</strong> If you use conversation mode
            and have history saving enabled, conversation transcripts (text
            only, not audio) may be stored temporarily on our servers.
          </li>
          <li>
            <strong>Support Communications:</strong> If you contact us for
            support, we collect the information you provide, including your
            email address and the content of your communications.
          </li>
        </ul>

        <h3>1.2 Information Collected Automatically</h3>
        <ul>
          <li>
            <strong>Usage Data:</strong> We collect information about how you
            use the Service, including the features you access, the languages
            you translate between, translation frequency, session duration, and
            subscription status.
          </li>
          <li>
            <strong>Device Information:</strong> We collect device type,
            operating system version, unique device identifiers (such as IDFV),
            and app version.
          </li>
          <li>
            <strong>Performance Data:</strong> We collect crash logs, error
            reports, and performance metrics to improve the Service.
          </li>
          <li>
            <strong>Network Information:</strong> We collect general network
            type (Wi-Fi or cellular) to optimize service delivery. We do not
            collect your IP address for tracking purposes, though it may be
            temporarily logged in server access logs.
          </li>
        </ul>

        <h3>1.3 Information We Do Not Collect</h3>
        <ul>
          <li>We do not collect precise geolocation data</li>
          <li>We do not access your contacts, photos, or other device data</li>
          <li>We do not collect payment or financial information (this is handled entirely by Apple)</li>
          <li>We do not use advertising identifiers (IDFA)</li>
          <li>We do not engage in cross-app tracking</li>
        </ul>

        <h2 id="use">2. How We Use Your Information</h2>
        <p>We use the information we collect to:</p>
        <ul>
          <li>Provide, maintain, and improve the Service</li>
          <li>Process and deliver translations</li>
          <li>Authenticate your identity and manage your account</li>
          <li>Store and sync your saved phrases and preferences</li>
          <li>Monitor usage against subscription limits</li>
          <li>Diagnose technical issues and improve performance</li>
          <li>Send service-related communications (e.g., subscription confirmations, security alerts)</li>
          <li>Comply with legal obligations and enforce our Terms of Use</li>
          <li>Develop new features and improve our AI translation models</li>
        </ul>
        <p>
          <strong>Important:</strong> We do not use your individual audio
          recordings or translations to train our AI models. Any model
          improvement is done using aggregated, anonymized, and
          de-identified data.
        </p>

        <h2 id="sharing">3. How We Share Your Information</h2>
        <p>
          We do not sell, rent, or trade your personal information to third
          parties. We may share your information in the following limited
          circumstances:
        </p>
        <ul>
          <li>
            <strong>Service Providers:</strong> We share information with
            trusted third-party service providers who assist us in operating
            the Service, including cloud hosting providers (for data storage
            and processing), AI model providers (for translation processing),
            and analytics providers (for aggregated usage analytics). These
            providers are contractually obligated to use your information only
            as necessary to provide services to us and to maintain appropriate
            security measures.
          </li>
          <li>
            <strong>Legal Requirements:</strong> We may disclose your
            information if required to do so by law, regulation, legal process,
            or governmental request, or when we believe in good faith that
            disclosure is necessary to protect our rights, protect your safety
            or the safety of others, investigate fraud, or respond to a
            government request.
          </li>
          <li>
            <strong>Business Transfers:</strong> In the event of a merger,
            acquisition, reorganization, bankruptcy, or other sale of all or a
            portion of our assets, your personal information may be
            transferred as part of that transaction. We will notify you via
            email and/or a prominent notice on our Service of any change in
            ownership or uses of your personal information.
          </li>
          <li>
            <strong>With Your Consent:</strong> We may share your information
            with third parties when you have given us explicit consent to do
            so.
          </li>
        </ul>

        <h2 id="retention">4. Data Retention</h2>
        <ul>
          <li>
            <strong>Audio Data:</strong> Voice recordings are processed in
            real time and deleted immediately after translation is complete.
            They are not stored on our servers.
          </li>
          <li>
            <strong>Account Information:</strong> Retained for as long as your
            account is active. Upon account deletion, your personal
            information will be deleted within 30 days, except where we are
            required to retain it for legal or regulatory purposes.
          </li>
          <li>
            <strong>Saved Phrases:</strong> Retained until you delete them or
            delete your account.
          </li>
          <li>
            <strong>Usage Data:</strong> Aggregated and anonymized usage data
            may be retained indefinitely for analytics and service improvement
            purposes.
          </li>
          <li>
            <strong>Server Logs:</strong> Access logs containing IP addresses
            are automatically deleted after 90 days.
          </li>
        </ul>

        <h2 id="security">5. Data Security</h2>
        <p>
          We implement industry-standard security measures to protect your
          information, including:
        </p>
        <ul>
          <li>Encryption of data in transit using TLS 1.3</li>
          <li>Encryption of data at rest using AES-256</li>
          <li>
            Secure authentication via Sign in with Apple with token-based
            session management
          </li>
          <li>Regular security audits and vulnerability assessments</li>
          <li>Access controls limiting employee access to personal data</li>
          <li>Infrastructure hosted on SOC 2 Type II certified cloud providers</li>
        </ul>
        <p>
          While we strive to protect your personal information, no method of
          transmission over the Internet or method of electronic storage is
          100% secure. We cannot guarantee absolute security.
        </p>

        <h2 id="rights">6. Your Rights and Choices</h2>

        <h3>6.1 Account Controls</h3>
        <ul>
          <li>
            <strong>Access and Update:</strong> You can access and update your
            account information within the App under Settings.
          </li>
          <li>
            <strong>Delete Saved Data:</strong> You can delete individual
            saved phrases or your entire phrase library within the App.
          </li>
          <li>
            <strong>Conversation History:</strong> You can disable history
            saving in Settings or delete individual conversations.
          </li>
          <li>
            <strong>Delete Account:</strong> You can request account deletion
            by contacting us at{" "}
            <a href={`mailto:${SITE.privacyEmail}`}>{SITE.privacyEmail}</a>.
            We will process your request within 30 days.
          </li>
        </ul>

        <h3>6.2 Communication Preferences</h3>
        <p>
          You may opt out of non-essential communications by following the
          unsubscribe instructions in any email we send or by contacting us
          directly. Note that you may continue to receive service-related
          communications necessary for the operation of your account.
        </p>

        <h2 id="gdpr">7. European Economic Area (EEA) / UK Users — GDPR</h2>
        <p>
          If you are located in the European Economic Area or the United
          Kingdom, you have additional rights under the General Data
          Protection Regulation (GDPR):
        </p>
        <ul>
          <li>
            <strong>Legal Basis for Processing:</strong> We process your
            personal data based on: (a) your consent; (b) the necessity to
            perform our contract with you (i.e., provide the Service); (c) our
            legitimate interests in improving and securing the Service; and (d)
            compliance with legal obligations.
          </li>
          <li>
            <strong>Right of Access:</strong> You have the right to request a
            copy of the personal data we hold about you.
          </li>
          <li>
            <strong>Right to Rectification:</strong> You have the right to
            request correction of inaccurate personal data.
          </li>
          <li>
            <strong>Right to Erasure:</strong> You have the right to request
            deletion of your personal data (&quot;right to be forgotten&quot;).
          </li>
          <li>
            <strong>Right to Restriction:</strong> You have the right to
            request that we restrict processing of your personal data.
          </li>
          <li>
            <strong>Right to Data Portability:</strong> You have the right to
            receive your personal data in a structured, commonly used, and
            machine-readable format.
          </li>
          <li>
            <strong>Right to Object:</strong> You have the right to object to
            processing of your personal data based on our legitimate
            interests.
          </li>
          <li>
            <strong>Right to Withdraw Consent:</strong> Where processing is
            based on consent, you may withdraw your consent at any time.
          </li>
        </ul>
        <p>
          To exercise any of these rights, contact us at{" "}
          <a href={`mailto:${SITE.privacyEmail}`}>{SITE.privacyEmail}</a>. We
          will respond to your request within 30 days. You also have the right
          to lodge a complaint with your local data protection authority.
        </p>

        <h2 id="ccpa">8. California Users — CCPA / CPRA</h2>
        <p>
          If you are a California resident, you have additional rights under
          the California Consumer Privacy Act (CCPA) as amended by the
          California Privacy Rights Act (CPRA):
        </p>
        <ul>
          <li>
            <strong>Right to Know:</strong> You have the right to request
            disclosure of the categories and specific pieces of personal
            information we have collected about you, the categories of sources,
            the business purpose for collecting it, and the categories of third
            parties with whom we share it.
          </li>
          <li>
            <strong>Right to Delete:</strong> You have the right to request
            deletion of your personal information, subject to certain
            exceptions.
          </li>
          <li>
            <strong>Right to Correct:</strong> You have the right to request
            correction of inaccurate personal information.
          </li>
          <li>
            <strong>Right to Opt-Out of Sale/Sharing:</strong> We do not sell
            or share your personal information for cross-context behavioral
            advertising.
          </li>
          <li>
            <strong>Right to Non-Discrimination:</strong> We will not
            discriminate against you for exercising your privacy rights.
          </li>
        </ul>
        <p>
          To exercise your rights, contact us at{" "}
          <a href={`mailto:${SITE.privacyEmail}`}>{SITE.privacyEmail}</a> or
          submit a request through the App. We will verify your identity and
          respond within 45 days.
        </p>
        <p>
          <strong>Categories of personal information collected in the past 12 months:</strong>
        </p>
        <ul>
          <li>Identifiers (name, email, Apple User ID)</li>
          <li>Internet or other electronic network activity information (usage data, device information)</li>
          <li>Audio information (voice recordings processed transiently for translation)</li>
        </ul>
        <p>
          We do not sell personal information. We do not use or disclose
          sensitive personal information for purposes other than those
          permitted under the CCPA/CPRA.
        </p>

        <h2 id="children">9. Children&apos;s Privacy</h2>
        <p>
          The Service is not directed to children under the age of 13. We do
          not knowingly collect personal information from children under 13.
          If we learn that we have collected personal information from a child
          under 13, we will promptly delete that information. If you believe
          that a child under 13 has provided us with personal information,
          please contact us at{" "}
          <a href={`mailto:${SITE.privacyEmail}`}>{SITE.privacyEmail}</a>.
        </p>

        <h2 id="international">10. International Data Transfers</h2>
        <p>
          Your information may be transferred to and processed in the United
          States and other countries where our service providers operate. These
          countries may have data protection laws that differ from the laws of
          your country. Where required, we implement appropriate safeguards
          for international data transfers, including Standard Contractual
          Clauses approved by the European Commission.
        </p>

        <h2 id="third-party-links">11. Third-Party Links</h2>
        <p>
          The Service may contain links to third-party websites or services
          that are not owned or controlled by us. We are not responsible for
          the privacy practices of such third parties. We encourage you to
          review the privacy policies of any third-party services you access
          through the Service.
        </p>

        <h2 id="cookies">12. Cookies and Tracking Technologies</h2>
        <p>
          Our Website may use essential cookies necessary for the functioning
          of the site. We do not use advertising cookies, tracking pixels, or
          cross-site tracking technologies. The App does not use cookies.
        </p>

        <h2 id="do-not-track">13. Do Not Track Signals</h2>
        <p>
          We honor Do Not Track (DNT) signals. When we detect a DNT signal,
          we do not track, plant cookies, or use advertising services.
        </p>

        <h2 id="changes">14. Changes to This Privacy Policy</h2>
        <p>
          We may update this Privacy Policy from time to time. If we make
          material changes, we will notify you by updating the &quot;Last
          Updated&quot; date and, for material changes, by providing notice
          through the App or by email. Your continued use of the Service after
          changes have been posted constitutes your acceptance of the revised
          Privacy Policy.
        </p>

        <h2 id="contact">15. Contact Us</h2>
        <p>
          If you have any questions, concerns, or requests regarding this
          Privacy Policy, please contact us:
        </p>
        <ul>
          <li>
            <strong>Privacy inquiries:</strong>{" "}
            <a href={`mailto:${SITE.privacyEmail}`}>{SITE.privacyEmail}</a>
          </li>
          <li>
            <strong>General support:</strong>{" "}
            <a href={`mailto:${SITE.supportEmail}`}>{SITE.supportEmail}</a>
          </li>
          <li>
            <strong>Mail:</strong> {SITE.companyName}, Attn: Privacy,{" "}
            {SITE.companyAddress}
          </li>
        </ul>
        <p>
          If you are an EEA or UK resident and wish to contact our Data
          Protection Officer, please email{" "}
          <a href={`mailto:${SITE.privacyEmail}`}>{SITE.privacyEmail}</a>{" "}
          with &quot;DPO Request&quot; in the subject line.
        </p>
      </LegalLayout>
    </>
  );
}
