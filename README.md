Entra ID Group Assignment Manager

A standalone WPF/PowerShell GUI tool to bypass Entra ID Free limitations and manage Enterprise Application group assignments via Microsoft Graph API.
The Problem

If you manage a Homelab or an Entra ID Free tenant, you are familiar with the paywall: You cannot assign Groups to Enterprise Applications without a Premium P1/P2 license. You are forced to assign users one by one through the Azure Portal GUI.
💡 The Solution

While the Azure Portal GUI restricts group assignments, the underlying Microsoft Graph API does not. By mapping a Group's Object ID directly to an Application's App Role ID, you can successfully grant group-based access.

Instead of running tedious manual scripts or Postman queries every time you need to grant access, this tool automates the entire API interaction within a modern, responsive "Zero-Touch" GUI.
✨ Features

    1. Foolproof Infrastructure Setup: Automatically creates the required App Registration, Self-Signed Certificate, and Service Principal with a single click.

    2. Certificate Authentication: Uses modern, secure certificate-based authentication (No Client Secrets).

    3. Visual Management: Search Apps, filter Azure AD Groups, and view current ACLs (Access Control Lists) in real-time.

    4. Smart Assignment: Automatically detects the correct App Roles and assigns Groups or Users instantly via API.

    5. Safety First: Prevents accidental overwrites, handles 403/404 API errors gracefully with Asynchronous Toasts, and features a zero-output background console.

    6. Auto-Persistence: Securely remembers your Tenant and Client IDs in the Windows Registry (HKCU\Software\EntraIDGroupAssistant).

    7. Multi-Admin Ready (Dynamic Naming): The initial setup dynamically names the Azure App Registration using your $HOSTNAME (e.g., EntraID-GroupManager-SAUL-PC). This prevents certificate collisions and naming duplications if multiple admins run the setup on the same tenant.
