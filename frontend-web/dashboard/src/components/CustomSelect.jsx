import { useState, useRef, useEffect } from "react";

/**
 * CustomSelect — Dropdown refinado reutilizable.
 * Props:
 *   value: string — valor seleccionado
 *   onChange: (value: string) => void
 *   options: Array<{ label: string, value: string }>
 *   placeholder: string — texto cuando no hay selección
 */
export default function CustomSelect({ value, onChange, options, placeholder }) {
  var [open, setOpen] = useState(false);
  var ref = useRef(null);

  // Click fuera para cerrar
  useEffect(function () {
    if (!open) return;
    function handler(e) {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false);
    }
    document.addEventListener("mousedown", handler);
    return function () { document.removeEventListener("mousedown", handler); };
  }, [open]);

  // Escape para cerrar
  useEffect(function () {
    if (!open) return;
    function handler(e) { if (e.key === "Escape") setOpen(false); }
    document.addEventListener("keydown", handler);
    return function () { document.removeEventListener("keydown", handler); };
  }, [open]);

  var selected = options.find(function (o) { return o.value === value; });
  var label = selected ? selected.label : placeholder || "Seleccionar";

  return (
    <div ref={ref} style={{ position: "relative", minWidth: 0 }}>
      <style>{`@keyframes csDropIn { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: translateY(0); } }
.cs-panel::-webkit-scrollbar { width: 6px; }
.cs-panel::-webkit-scrollbar-track { background: transparent; margin: 4px 0; }
.cs-panel::-webkit-scrollbar-thumb { background: #E2E8F0; border-radius: 3px; }
.cs-panel::-webkit-scrollbar-thumb:hover { background: #CBD5E1; }`}</style>
      {/* Trigger */}
      <button
        type="button"
        onClick={function () { setOpen(!open); }}
        style={TRIGGER(open, !!value)}
      >
        <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", flex: 1, textAlign: "left", color: value ? "#1E293B" : "#94A3B8" }}>{label}</span>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="2" style={{ flexShrink: 0, transition: "transform 150ms ease", transform: open ? "rotate(180deg)" : "rotate(0deg)" }}><polyline points="6 9 12 15 18 9"/></svg>
      </button>

      {/* Panel */}
      {open && (
        <div className="cs-panel" style={PANEL}>
          {options.map(function (opt) {
            var isActive = opt.value === value;
            return (
              <div
                key={opt.value}
                onClick={function () { onChange(opt.value); setOpen(false); }}
                style={OPTION(isActive)}
                onMouseEnter={function (e) { if (!isActive) e.currentTarget.style.backgroundColor = "#F1F5F9"; }}
                onMouseLeave={function (e) { if (!isActive) e.currentTarget.style.backgroundColor = "transparent"; }}
              >
                <span style={{ flex: 1 }}>{opt.label}</span>
                {isActive && <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563EB" strokeWidth="2.5" style={{ flexShrink: 0 }}><polyline points="20 6 9 17 4 12"/></svg>}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function TRIGGER(open, hasValue) {
  return {
    display: "flex",
    alignItems: "center",
    gap: 6,
    height: 38,
    padding: "0 10px",
    borderRadius: 8,
    border: open ? "1px solid #2563EB" : "0.5px solid #CBD5E1",
    backgroundColor: "#F8FAFC",
    fontSize: 13,
    fontFamily: "'Inter',sans-serif",
    color: hasValue ? "#1E293B" : "#94A3B8",
    cursor: "pointer",
    width: "100%",
    boxSizing: "border-box",
    boxShadow: open ? "0 0 0 3px rgba(37,99,235,0.1)" : "none",
    transition: "border-color 150ms ease, box-shadow 150ms ease",
    outline: "none",
  };
}

var PANEL = {
  position: "absolute",
  top: "calc(100% + 4px)",
  left: 0,
  right: 0,
  backgroundColor: "#fff",
  border: "0.5px solid #CBD5E1",
  borderRadius: 8,
  boxShadow: "0 4px 16px rgba(0,0,0,0.08)",
  padding: 4,
  zIndex: 50,
  maxHeight: 220,
  overflowY: "auto",
  animation: "csDropIn 150ms ease",
};

function OPTION(isActive) {
  return {
    padding: "8px 12px",
    borderRadius: 6,
    fontSize: 13,
    fontFamily: "'Inter',sans-serif",
    color: isActive ? "#2563EB" : "#1E293B",
    fontWeight: isActive ? 500 : 400,
    backgroundColor: isActive ? "#EFF6FF" : "transparent",
    cursor: "pointer",
    display: "flex",
    alignItems: "center",
    gap: 8,
    transition: "background-color 100ms ease",
  };
}
