using System.Windows.Forms;

public class BlockMessage
{
    public static void Main(string[] args)
    {
        // Message to display
        string message = "This file is blocked from opening in Windows!";

        // Title for the message box
        string title = "File Blocked";

        // Display the message box with OK button
        MessageBox.Show(message, title, MessageBoxButtons.OK, MessageBoxIcon.Warning);
    }
}

// mcs -target:winexe -r:System.Windows.Forms.dll -out:BlockMessage.exe BlockMessage.cs