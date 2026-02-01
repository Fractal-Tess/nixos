#!/usr/bin/env python3

import sys
import os
import subprocess
import re

def quick_vulnerability_scan(binary_path, output_dir):
    """Perform quick vulnerability scanning on binary"""

    print(f"[+] Starting vulnerability scan for: {binary_path}")

    vulnerabilities = []
    security_analysis = []
    exploitation_hints = []

    try:
        # Get strings output
        result = subprocess.run(['strings', binary_path], capture_output=True, text=True)
        strings_output = result.stdout

        # 1. Dangerous function detection
        print("[+] Scanning for dangerous functions...")
        dangerous_funcs = {
            'gets': 'Classic buffer overflow - no bounds checking',
            'strcpy': 'Buffer overflow - no size limit on destination',
            'strcat': 'Buffer overflow - no size limit on destination',
            'sprintf': 'Buffer overflow & format string - no bounds checking',
            'vsprintf': 'Buffer overflow & format string - no bounds checking',
            'scanf': 'Potential buffer overflow - depends on format string',
            'system': 'Command injection possible if user-controlled input',
            'popen': 'Command injection possible if user-controlled input',
            'exec': 'Command injection possible if user-controlled input'
        }

        for func, desc in dangerous_funcs.items():
            if func in strings_output:
                vulnerabilities.append(f"⚠️  Dangerous function found: {func} - {desc}")

                # Add specific exploitation hints
                if func == 'gets':
                    exploitation_hints.append("💡 Buffer overflow via gets() - Classic stack smashing technique")
                elif func in ['strcpy', 'strcat']:
                    exploitation_hints.append(f"💡 Buffer overflow via {func}() - Overwrite return address")
                elif func in ['sprintf', 'vsprintf']:
                    exploitation_hints.append(f"💡 {func}() can lead to buffer overflow AND format string attacks")
                elif func == 'system':
                    exploitation_hints.append("💡 Command injection possible - Try to control system() argument")

        # 2. Format string detection
        print("[+] Scanning for format string vulnerabilities...")
        format_patterns = ['%x', '%p', '%n', '%s']
        format_vulns = []
        for pattern in format_patterns:
            if pattern in strings_output:
                format_vulns.append(pattern)

        if format_vulns:
            vulnerabilities.append(f"🔍 Format string patterns found: {', '.join(format_vulns)}")
            exploitation_hints.append("💡 Format string vulnerability - Try arbitrary write/read via %n")

        # 3. Hardcoded secrets detection
        print("[+] Scanning for hardcoded secrets...")
        secret_patterns = {
            'password': 'Potential password string',
            'secret': 'Potential secret key/token',
            'key': 'Potential cryptographic key',
            'token': 'Potential authentication token',
            'flag': 'CTF flag or debug flag',
            'admin': 'Potential admin credentials'
        }

        for pattern, desc in secret_patterns.items():
            if pattern in strings_output.lower():
                # Find the actual string containing the pattern
                lines = strings_output.split('\n')
                for line in lines:
                    if pattern in line.lower():
                        vulnerabilities.append(f"🔑 {desc}: '{line.strip()}'")
                        break

        # 4. Network-related patterns
        print("[+] Scanning for network-related code...")
        network_patterns = ['socket', 'bind', 'listen', 'accept', 'connect', 'send', 'recv']
        network_found = []
        for pattern in network_patterns:
            if pattern in strings_output:
                network_found.append(pattern)

        if network_found:
            vulnerabilities.append(f"🌐 Network functions found: {', '.join(network_found)}")
            exploitation_hints.append("💡 Network binary - May require socket manipulation or network protocol analysis")

        # 5. File I/O patterns
        print("[+] Scanning for file operations...")
        file_patterns = ['fopen', 'open', 'read', 'write', 'fread', 'fwrite', 'fgets']
        file_found = []
        for pattern in file_patterns:
            if pattern in strings_output:
                file_found.append(pattern)

        if file_found:
            vulnerabilities.append(f"📁 File operations found: {', '.join(file_found)}")

        # 6. Try to get basic file info
        print("[+] Getting file information...")
        try:
            file_result = subprocess.run(['file', binary_path], capture_output=True, text=True)
            file_info = file_result.stdout.strip()

            if 'ELF' in file_info:
                security_analysis.append("📋 ELF binary detected")

                # Try checksec if available
                try:
                    checksec_result = subprocess.run(['checksec', '--file=' + binary_path],
                                                  capture_output=True, text=True)
                    if checksec_result.returncode == 0:
                        security_analysis.append("🛡️  Security Features Analysis:")
                        for line in checksec_result.stdout.split('\n'):
                            if line.strip():
                                security_analysis.append(f"   {line.strip()}")
                except:
                    security_analysis.append("⚠️  checksec not available for detailed analysis")
        except:
            security_analysis.append("⚠️  Could not determine file type")

        # Generate exploitation suggestions
        print("[+] Generating exploitation suggestions...")
        if vulnerabilities:
            exploitation_hints.append("🎯 Start with basic fuzzing to find buffer overflow offsets")
            exploitation_hints.append("🔧 Use pwntools: cyclic(N) -> find crash -> cyclic_find(crash_addr)")

            if any('gets' in v or 'strcpy' in v or 'strcat' in v for v in vulnerabilities):
                exploitation_hints.append("💥 Buffer overflow detected - Classic ret2win technique possible")

            if any('format string' in v for v in vulnerabilities):
                exploitation_hints.append("📝 Format string - Try arbitrary writes using %n")
                exploitation_hints.append("🎯 Target: GOT entries, __stack_chk_fail, or return addresses")

            if 'system' in strings_output:
                exploitation_hints.append("🚀 system() found - Try to control argument for command injection")

        # Write results to files
        print("[+] Writing analysis results...")

        # Main vulnerability report
        with open(os.path.join(output_dir, 'vulnerability_scan.txt'), 'w') as f:
            f.write("╔══════════════════════════════════════════════════════════════╗\n")
            f.write("║                    VULNERABILITY QUICK SCAN                  ║\n")
            f.write("╚══════════════════════════════════════════════════════════════╝\n\n")

            f.write("🔍 CRITICAL FINDINGS:\n")
            if vulnerabilities:
                for vuln in vulnerabilities:
                    f.write(f"{vuln}\n")
            else:
                f.write("✅ No obvious vulnerabilities detected in static analysis\n")

            f.write(f"\n🛡️  SECURITY ANALYSIS:\n")
            for sec in security_analysis:
                f.write(f"{sec}\n")

            f.write(f"\n🎯 EXPLOITATION SUGGESTIONS:\n")
            for hint in exploitation_hints:
                f.write(f"{hint}\n")

        # Exploitation hints file
        with open(os.path.join(output_dir, 'exploitation_hints.txt'), 'w') as f:
            f.write("╔══════════════════════════════════════════════════════════════╗\n")
            f.write("║                      EXPLOITATION HINTS                     ║\n")
            f.write("╚══════════════════════════════════════════════════════════════╝\n\n")

            if any('gets' in v or 'strcpy' in v or 'strcat' in v for v in vulnerabilities):
                f.write("💥 BUFFER OVERFLOW TECHNIQUES:\n")
                f.write("1. Use cyclic pattern to find offset: cyclic(100)\n")
                f.write("2. Find crash address in debugger\n")
                f.write("3. Calculate offset: cyclic_find(0xdeadbeef)\n")
                f.write("4. Build payload: offset * 'A' + return_address\n\n")

            if any('format string' in v for v in vulnerabilities):
                f.write("📝 FORMAT STRING TECHNIQUES:\n")
                f.write("1. Find format string vulnerability location\n")
                f.write("2. Use fmtstr_payload for arbitrary writes\n")
                f.write("3. Target GOT entries or return addresses\n")
                f.write("4. Example: payload = fmtstr_payload(7, {win_addr: 0xdeadbeef})\n\n")

            if 'system' in strings_output:
                f.write("🚀 COMMAND INJECTION TECHNIQUES:\n")
                f.write("1. Find where user input reaches system()\n")
                f.write("2. Try to inject shell commands\n")
                f.write("3. Common payloads: ;/bin/sh, &&/bin/sh, |/bin/sh\n\n")

            f.write("🔧 GENERAL EXPLOITATION STEPS:\n")
            f.write("1. Start with basic fuzzing to find crashes\n")
            f.write("2. Use gdb/pwndbg to analyze crash\n")
            f.write("3. Build exploit step by step\n")
            f.write("4. Test locally, then adapt for remote if needed\n")

        print(f"[+] Vulnerability scan completed!")
        print(f"[+] Reports saved to: {output_dir}")
        print(f"[+] Found {len(vulnerabilities)} potential issues")

        return True

    except Exception as e:
        print(f"[!] Error during vulnerability scan: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 vuln_scan.py <binary_path> <output_directory>")
        sys.exit(1)

    binary_path = sys.argv[1]
    output_dir = sys.argv[2]

    if not os.path.exists(binary_path):
        print(f"[!] Binary not found: {binary_path}")
        sys.exit(1)

    if not os.path.exists(output_dir):
        print(f"[!] Output directory not found: {output_dir}")
        sys.exit(1)

    if quick_vulnerability_scan(binary_path, output_dir):
        print("[+] Vulnerability analysis successful!")
        sys.exit(0)
    else:
        print("[!] Vulnerability analysis failed!")
        sys.exit(1)