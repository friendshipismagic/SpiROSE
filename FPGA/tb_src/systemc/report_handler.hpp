#ifdef REPORT_HANDLER_HPP
#error report_handler.hpp should only be included once
#endif
#define REPORT_HANDLER_HPP

// Should be included only in main.cpp

#include <systemc.h>
#include <array>

const std::array<std::string, 5> severity2str = {"INFO", "WARNING", "ERROR",
                                                 "FATAL", "UNKNOWN_SEVERITY"};

std::array<int, 5> reportsCount;

void report_handler(const sc_report& report, const sc_actions& actions) {
    // dump out report
    reportsCount[report.get_severity()]++;
    cout << "[" << severity2str[report.get_severity()]
         << "]: " << report.get_msg_type();
    cout << " -->";
    for (int n = 0; n < 32; n++) {
        sc_actions action = actions & 1 << n;
        if (action) {
            cout << " ";
            switch (action) {
                case SC_UNSPECIFIED:
                    cout << "unspecified";
                    break;
                case SC_DO_NOTHING:
                    cout << "do-nothing";
                    break;
                case SC_THROW:
                    cout << "throw";
                    break;
                case SC_LOG:
                    cout << "log";
                    break;
                case SC_DISPLAY:
                    cout << "display";
                    break;
                case SC_CACHE_REPORT:
                    cout << "cache-report";
                    break;
                case SC_INTERRUPT:
                    cout << "interrupt";
                    break;
                case SC_STOP:
                    cout << "stop";
                    break;
                case SC_ABORT:
                    cout << "abort";
                    break;
                default:
                    cout << "UNKNOWN";
            }
        }
    }
    cout << endl;
    cout << " msg  = " << report.get_msg() << endl;
    cout << " file = " << report.get_file_name() << endl;
    cout << " line = " << report.get_line_number() << endl;
    cout << " time = " << report.get_time() << endl;
    const char* name = report.get_process_name();
    cout << " process=" << (name ? name : "<none>") << endl;
}

void printReport() {
    cout << endl << "Report:" << endl;
    for (int i = 0; i < reportsCount.size(); ++i) {
        cout << "[" << severity2str[i] << "]: " << reportsCount[i] << endl;
    }
}

int errorCount() { return reportsCount[SC_ERROR] + reportsCount[SC_FATAL]; }

