import { forwardRef } from "react";
import DatePicker, { registerLocale } from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import { es } from "date-fns/locale";

registerLocale("es", es);

/**
 * CustomDatePicker — Date picker estilizado.
 * Props:
 *   value: string (YYYY-MM-DD) o ""
 *   onChange: (value: string) => void — devuelve YYYY-MM-DD o ""
 *   placeholder: string
 *   minDate: string (YYYY-MM-DD) — fecha mínima
 *   maxDate: string (YYYY-MM-DD) — fecha máxima
 */
export default function CustomDatePicker({ value, onChange, placeholder, minDate, maxDate }) {
  var selected = value ? new Date(value + "T00:00:00") : null;
  var min = minDate ? new Date(minDate + "T00:00:00") : null;
  var max = maxDate ? new Date(maxDate + "T00:00:00") : null;

  function handleChange(date) {
    if (!date) { onChange(""); return; }
    var y = date.getFullYear();
    var m = String(date.getMonth() + 1).padStart(2, "0");
    var d = String(date.getDate()).padStart(2, "0");
    onChange(y + "-" + m + "-" + d);
  }

  return (
    <div className="cdp-wrapper">
      <style>{CDP_STYLES}</style>
      <DatePicker
        selected={selected}
        onChange={handleChange}
        locale="es"
        dateFormat="dd/MM/yyyy"
        placeholderText={placeholder || "dd/mm/aaaa"}
        minDate={min}
        maxDate={max}
        isClearable={!!value}
        customInput={<CustomInput />}
        popperPlacement="bottom-start"
        showMonthDropdown
        showYearDropdown
        dropdownMode="select"
      />
    </div>
  );
}

var CustomInput = forwardRef(function (props, ref) {
  return (
    <button type="button" ref={ref} onClick={props.onClick} style={TRIGGER_STYLE}>
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#94A3B8" strokeWidth="2" style={{ flexShrink: 0 }}><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
      <span style={{ flex: 1, textAlign: "left", color: props.value ? "#1E293B" : "#94A3B8", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{props.value || props.placeholder}</span>
    </button>
  );
});

var TRIGGER_STYLE = {
  display: "flex",
  alignItems: "center",
  gap: 8,
  height: 38,
  padding: "0 12px",
  borderRadius: 10,
  border: "1px solid #E2E8F0",
  backgroundColor: "#F8FAFC",
  fontSize: 13,
  fontFamily: "'Inter',sans-serif",
  cursor: "pointer",
  width: "100%",
  boxSizing: "border-box",
  transition: "border-color 0.2s ease, box-shadow 0.2s ease",
  outline: "none",
};

var CDP_STYLES = `
.cdp-wrapper { width: 100%; }
.cdp-wrapper .react-datepicker-wrapper { width: 100%; }
.cdp-wrapper .react-datepicker__input-container { width: 100%; }
.cdp-wrapper .react-datepicker-popper { z-index: 60 !important; }
.cdp-wrapper .react-datepicker {
  font-family: 'Inter', sans-serif;
  border: 1px solid #E2E8F0;
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.08);
  overflow: hidden;
}
.cdp-wrapper .react-datepicker__header {
  background: #F8FAFC;
  border-bottom: 1px solid #E2E8F0;
  padding: 12px 8px 8px;
}
.cdp-wrapper .react-datepicker__current-month {
  font-size: 14px;
  font-weight: 600;
  color: #1E293B;
  margin-bottom: 8px;
}
.cdp-wrapper .react-datepicker__day-names {
  display: flex;
  justify-content: space-around;
}
.cdp-wrapper .react-datepicker__day-name {
  color: #64748B;
  font-size: 11px;
  font-weight: 500;
  width: 32px;
  margin: 0;
}
.cdp-wrapper .react-datepicker__month {
  padding: 4px;
}
.cdp-wrapper .react-datepicker__week {
  display: flex;
  justify-content: space-around;
}
.cdp-wrapper .react-datepicker__day {
  width: 32px;
  height: 32px;
  line-height: 32px;
  border-radius: 8px;
  font-size: 13px;
  color: #1E293B;
  margin: 2px 0;
  transition: background 0.15s ease;
}
.cdp-wrapper .react-datepicker__day:hover {
  background: #EFF6FF;
  color: #2563EB;
}
.cdp-wrapper .react-datepicker__day--selected,
.cdp-wrapper .react-datepicker__day--keyboard-selected {
  background: #2563EB !important;
  color: #fff !important;
  font-weight: 600;
}
.cdp-wrapper .react-datepicker__day--today {
  font-weight: 700;
  color: #2563EB;
}
.cdp-wrapper .react-datepicker__day--disabled {
  color: #CBD5E1;
}
.cdp-wrapper .react-datepicker__navigation {
  top: 12px;
}
.cdp-wrapper .react-datepicker__navigation-icon::before {
  border-color: #64748B;
  border-width: 2px 2px 0 0;
  width: 8px;
  height: 8px;
}
.cdp-wrapper .react-datepicker__month-dropdown-container,
.cdp-wrapper .react-datepicker__year-dropdown-container {
  margin: 0 4px;
}
.cdp-wrapper .react-datepicker__month-dropdown-container select,
.cdp-wrapper .react-datepicker__year-dropdown-container select {
  padding: 4px 8px;
  border-radius: 6px;
  border: 1px solid #E2E8F0;
  font-size: 12px;
  font-family: 'Inter', sans-serif;
  color: #1E293B;
  background: #fff;
  cursor: pointer;
}
.cdp-wrapper .react-datepicker__close-icon::after {
  background: #94A3B8;
  font-size: 14px;
  width: 16px;
  height: 16px;
  line-height: 14px;
}
.cdp-wrapper .react-datepicker__triangle { display: none; }
`;
