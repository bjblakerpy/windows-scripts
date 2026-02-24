# Windows Utility Scripts

A collection of PowerShell scripts for Windows 11 maintenance, cleanup, and automated updates.

## 🚀 Getting Started

### Prerequisites
- Windows 10/11
- PowerShell 5.1 or later (PowerShell 7 recommended)
- Administrator privileges for most cleanup and update operations.

### Deployment
1. Clone this repository:
   ```powershell
   git clone https://github.com/bjblakerpy/windows-scripts.git
   cd windows-scripts
   ```
2. Unblock scripts if necessary:
   ```powershell
   Get-ChildItem -Path . -Filter *.ps1 | Unblock-File
   ```

## 🛠 Included Scripts

| Script | Description |
| :--- | :--- |
| `Win11Cleanup.ps1` | Performs deep system cleanup, including temporary file removal and system optimization. |
| `WingetUpdate.ps1` | Uses Windows Package Manager (winget) to update all installed applications to their latest versions. |

## 🧬 Extending the Collection
This repository is a living collection of Windows automation. To add new scripts:
1. Place your `.ps1` script in the root directory.
2. Ensure the script includes a brief description in the comments.
3. For scripts requiring admin rights, consider adding a check at the beginning of the script.

## ⚖️ License
This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
