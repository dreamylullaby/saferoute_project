/**
 * Pestaña Resumen — iframe de Looker Studio
 */
export default function TabResumen() {
  return (
    <div style={styles.container}>
      <iframe
        title="SafeRoute - Dashboard Looker Studio"
        width="100%"
        height="900"
        src="https://datastudio.google.com/embed/reporting/2eac45b8-40c6-45ad-9f37-b0bbd7f8bcdd/page/AdEwF"
        frameBorder="0"
        style={{ border: 0, borderRadius: "12px" }}
        allowFullScreen
        sandbox="allow-storage-access-by-user-activation allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox"
      />
    </div>
  );
}

const styles = {
  container: {
    backgroundColor: "#fff",
    borderRadius: "12px",
    padding: "16px",
    boxShadow: "0 1px 4px rgba(0,0,0,0.06)",
  },
};
