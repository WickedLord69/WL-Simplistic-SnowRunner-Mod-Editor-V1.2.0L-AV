using System;
using System.IO;
using System.Reflection;
using System.Text;
using System.Windows.Forms;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

[assembly: AssemblyTitle("WL Simplistic SnowRunner Mod Editor")]
[assembly: AssemblyDescription("WL Simplistic SnowRunner Mod Editor v1.2.0L")]
[assembly: AssemblyCompany("Wicked Lord")]
[assembly: AssemblyProduct("WL Simplistic SnowRunner Mod Editor")]
[assembly: AssemblyCopyright("Copyright © Wicked Lord 2026")]
[assembly: AssemblyVersion("1.2.0.0")]
[assembly: AssemblyFileVersion("1.2.0.0")]

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        Environment.SetEnvironmentVariable("WL_SSME_ROOT", root);
        string icon = Path.Combine(root, "assets", "WL-icon.ico");
        string logo = Path.Combine(root, "assets", "WL-header-logo.png");
        if (File.Exists(icon)) Environment.SetEnvironmentVariable("WL_SSME_ICON", icon);
        if (File.Exists(logo)) Environment.SetEnvironmentVariable("WL_SSME_LOGO", logo);

        try
        {
            string script;
            using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("WL.Editor.ps1"))
            {
                if (s == null) throw new InvalidOperationException("Embedded WL editor resource was not found.");
                using (var r = new StreamReader(s, Encoding.UTF8, true)) script = r.ReadToEnd();
            }

            InitialSessionState iss = InitialSessionState.CreateDefault();
            using (Runspace runspace = RunspaceFactory.CreateRunspace(iss))
            {
                runspace.ApartmentState = System.Threading.ApartmentState.STA;
                runspace.ThreadOptions = PSThreadOptions.ReuseThread;
                runspace.Open();
                using (PowerShell ps = PowerShell.Create())
                {
                    ps.Runspace = runspace;
                    ps.AddScript(script);
                    ps.Invoke();
                    if (ps.HadErrors)
                    {
                        var sb = new StringBuilder();
                        sb.AppendLine("WL reported PowerShell errors:");
                        sb.AppendLine();
                        foreach (var e in ps.Streams.Error) sb.AppendLine(e.ToString());
                        MessageBox.Show(sb.ToString(), "WL Simplistic SnowRunner Mod Editor - Startup Diagnostic",
                            MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show("WL could not start.\n\n" + ex.ToString(),
                "WL Simplistic SnowRunner Mod Editor - Startup Diagnostic", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
