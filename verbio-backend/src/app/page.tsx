export default function Home() {
  return (
    <main style={{
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '100vh',
      fontFamily: 'system-ui, -apple-system, sans-serif',
      background: 'linear-gradient(135deg, #FFFEF7 0%, #FEF3C7 100%)',
    }}>
      <div style={{
        textAlign: 'center',
        padding: '2rem',
      }}>
        <h1 style={{
          fontSize: '3rem',
          fontWeight: 700,
          color: '#1C1917',
          marginBottom: '1rem',
        }}>
          Verbio API
        </h1>
        <p style={{
          fontSize: '1.25rem',
          color: '#57534E',
          marginBottom: '2rem',
        }}>
          Real-time voice translation backend
        </p>
        <div style={{
          display: 'flex',
          gap: '1rem',
          justifyContent: 'center',
        }}>
          <a
            href="/api/health"
            style={{
              padding: '0.75rem 1.5rem',
              background: '#F59E0B',
              color: 'white',
              borderRadius: '8px',
              textDecoration: 'none',
              fontWeight: 500,
            }}
          >
            Health Check
          </a>
        </div>
        <p style={{
          marginTop: '3rem',
          fontSize: '0.875rem',
          color: '#78716C',
        }}>
          Version 1.0.0
        </p>
      </div>
    </main>
  )
}
