/* ==========================================================================
   SHARED DUTY SCHEDULE JS ENGINE - DIABETESCARE (2026)
   Used across Doctor, Receptionist, Lab Tech, Admin Schedule Views
   ========================================================================== */

(function (window) {
    "use strict";

    const DutySchedule = {
        getISOWeeksInYear: function (year) {
            const d = new Date(year, 11, 31);
            const week = this.getISOWeek(d);
            return week === 1 ? this.getISOWeek(new Date(year, 11, 24)) : week;
        },

        getISOWeek: function (d) {
            const date = new Date(d.getTime());
            date.setHours(0, 0, 0, 0);
            date.setDate(date.getDate() + 3 - ((date.getDay() + 6) % 7));
            const week1 = new Date(date.getFullYear(), 0, 4);
            return 1 + Math.round(((date.getTime() - week1.getTime()) / 86400000 - 3 + ((week1.getDay() + 6) % 7)) / 7);
        },

        getWeekDates: function (year, week) {
            const simple = new Date(year, 0, 1 + (week - 1) * 7);
            const dow = simple.getDay();
            const ISOweekStart = simple;
            if (dow <= 4) {
                ISOweekStart.setDate(simple.getDate() - simple.getDay() + 1);
            } else {
                ISOweekStart.setDate(simple.getDate() + 8 - simple.getDay());
            }

            const dates = [];
            for (let i = 0; i < 7; i++) {
                const date = new Date(ISOweekStart);
                date.setDate(ISOweekStart.getDate() + i);
                dates.push(date);
            }
            return dates;
        },

        formatDateVN: function (d) {
            const day = String(d.getDate()).padStart(2, "0");
            const month = String(d.getMonth() + 1).padStart(2, "0");
            return `${day}/${month}`;
        },

        formatISO: function (d) {
            const year = d.getFullYear();
            const month = String(d.getMonth() + 1).padStart(2, "0");
            const day = String(d.getDate()).padStart(2, "0");
            return `${year}-${month}-${day}`;
        },

        populateYearAndWeekSelectors: function (yearSelectId, weekSelectId, defaultYear, defaultWeek) {
            const yearSelect = document.getElementById(yearSelectId);
            const weekSelect = document.getElementById(weekSelectId);
            if (!yearSelect || !weekSelect) return;

            const now = new Date();
            const currentYear = defaultYear || now.getFullYear();
            const currentWeek = defaultWeek || this.getISOWeek(now);

            // Populate Years (2 years back, 2 years forward)
            yearSelect.innerHTML = "";
            for (let y = currentYear - 2; y <= currentYear + 2; y++) {
                const opt = document.createElement("option");
                opt.value = y;
                opt.textContent = `Năm ${y}`;
                if (y === currentYear) opt.selected = true;
                yearSelect.appendChild(opt);
            }

            this.updateWeekOptions(yearSelectId, weekSelectId, currentWeek);
        },

        updateWeekOptions: function (yearSelectId, weekSelectId, selectedWeek) {
            const yearSelect = document.getElementById(yearSelectId);
            const weekSelect = document.getElementById(weekSelectId);
            if (!yearSelect || !weekSelect) return;

            const year = parseInt(yearSelect.value, 10);
            const totalWeeks = this.getISOWeeksInYear(year);
            const now = new Date();
            const currentYear = now.getFullYear();
            const currentWeek = this.getISOWeek(now);

            weekSelect.innerHTML = "";
            for (let w = 1; w <= totalWeeks; w++) {
                const dates = this.getWeekDates(year, w);
                const startStr = this.formatDateVN(dates[0]);
                const endStr = this.formatDateVN(dates[6]);
                
                const opt = document.createElement("option");
                opt.value = this.formatISO(dates[0]);
                let label = `Tuần ${String(w).padStart(2, '0')} [${startStr} - ${endStr}]`;
                if (year === currentYear && w === currentWeek) {
                    label += " (Hiện tại)";
                }
                opt.textContent = label;
                if (w === (selectedWeek || currentWeek)) opt.selected = true;
                weekSelect.appendChild(opt);
            }
        }
    };

    window.DutyScheduleEngine = DutySchedule;
})(window);
