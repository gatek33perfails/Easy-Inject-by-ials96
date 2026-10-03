using System;
using System.CodeDom.Compiler;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.Versioning;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Markup;
using System.Windows.Media;
using System.Windows.Shapes;

[assembly: CompilationRelaxations(8)]
[assembly: RuntimeCompatibility(WrapNonExceptionThrows = true)]
[assembly: Debuggable(DebuggableAttribute.DebuggingModes.IgnoreSymbolStoreSequencePoints)]
[assembly: TargetFramework(".NETCoreApp,Version=v8.0", FrameworkDisplayName = ".NET 8.0")]
[assembly: AssemblyCompany("ials96")]
[assembly: AssemblyConfiguration("Release")]
[assembly: AssemblyFileVersion("1.0.0.0")]
[assembly: AssemblyInformationalVersion("1.0.0+7ad772ebd89ec48488d99a8ceb66ede8716cfc77")]
[assembly: AssemblyProduct("Easy Inject by ials96")]
[assembly: AssemblyTitle("EasyInject")]
[assembly: TargetPlatform("Windows7.0")]
[assembly: SupportedOSPlatform("Windows7.0")]
[assembly: AssemblyVersion("1.0.0.0")]
[module: RefSafetyRules(11)]
namespace BO2InjectorGUI;

public class MainWindow : Window, IComponentConnector
{
	private enum ConsoleTarget
	{
		Ps4 = 0,
		Ps5 = 1
	}

	private static readonly int[] Ps4LoaderPorts = new int[4] { 9020, 9021, 9022, 9090 };

	private static readonly int[] Ps5LoaderPorts = new int[3] { 9021, 9020, 9022 };

	private readonly Brush activeBrush = new SolidColorBrush(Color.FromRgb(byte.MaxValue, 122, 0));

	private readonly Brush doneBrush = new SolidColorBrush(Color.FromRgb(68, 227, 154));

	private CancellationTokenSource? operationCts;

	private int operationVersion;

	private ConsoleTarget selectedTarget = ConsoleTarget.Ps5;

	internal Ellipse dot;

	internal TextBlock lblStatus;

	internal TextBox txtIp;

	internal Button btnPs4OneClick;

	internal Button btnPs5OneClick;

	internal Button btnAdminSetup;

	internal TextBox txtLog;

	private bool _contentLoaded;

	private static string SettingsFile => System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "EasyInject-ials96", "console-ip.txt");

	public MainWindow()
	{
		InitializeComponent();
		btnPs4OneClick.Click += async delegate
		{
			selectedTarget = ConsoleTarget.Ps4;
			btnAdminSetup.Content = "ADMIN MENU SETUP / PS4 NEXUS";
			await QueueOneClickAsync(selectedTarget);
		};
		btnPs5OneClick.Click += async delegate
		{
			selectedTarget = ConsoleTarget.Ps5;
			btnAdminSetup.Content = "ADMIN MENU SETUP / PS5 NEXUS";
			await QueueOneClickAsync(selectedTarget);
		};
		btnAdminSetup.Click += async delegate
		{
			await QueueAdminSetupAsync();
		};
		LoadSavedIp();
		txtIp.TextChanged += delegate
		{
			SaveIpIfValid();
		};
		base.Closing += delegate
		{
			SaveIpIfValid();
		};
		Log("Ready — جاهز");
	}

	private async Task QueueAdminSetupAsync()
	{
		string ip = txtIp.Text.Trim();
		if (!IPAddress.TryParse(ip, out IPAddress _))
		{
			Fail("Invalid IP address / عنوان IP غير صحيح");
			return;
		}
		int version = Interlocked.Increment(ref operationVersion);
		CancellationTokenSource nextCts = new CancellationTokenSource();
		CancellationTokenSource cancellationTokenSource = Interlocked.Exchange(ref operationCts, nextCts);
		if (cancellationTokenSource != null)
		{
			try
			{
				cancellationTokenSource.Cancel();
			}
			catch (ObjectDisposedException)
			{
			}
		}
		string text = ((selectedTarget == ConsoleTarget.Ps5) ? "PS5" : "PS4");
		Log("Preparing Admin menu services for " + text + "...");
		try
		{
			SetStatus("ADMIN SETUP " + text, success: false);
			await EnsureNexusAsync(ip, selectedTarget, nextCts.Token);
			if (!(await IsPortOpenAsync(ip, 2567, 700, nextCts.Token)))
			{
				throw new InvalidOperationException("Nexus is still OFF. Open ELF Loader on the console, then press ADMIN MENU SETUP again.");
			}
			int preferredFtp = ((selectedTarget == ConsoleTarget.Ps5) ? 1337 : 2121);
			int alternateFtp = ((selectedTarget == ConsoleTarget.Ps5) ? 2121 : 1337);
			int num = ((!(await IsPortOpenAsync(ip, preferredFtp, 700, nextCts.Token))) ? ((await IsPortOpenAsync(ip, alternateFtp, 700, nextCts.Token)) ? alternateFtp : 0) : preferredFtp);
			int ftpPort = num;
			if (ftpPort == 0)
			{
				throw new InvalidOperationException("FTP is OFF. Enable FTP in etaHEN/GoldHEN, then press ADMIN MENU SETUP again.");
			}
			if (await IsPortOpenAsync(ip, 744, 500, nextCts.Token))
			{
				Ps4DebugClient client = new Ps4DebugClient();
				try
				{
					await Task.Run(delegate
					{
						client.Connect(ip);
					}, nextCts.Token);
					TryNotify(client, $"Easy Inject: Admin ready - Nexus + FTP {ftpPort}");
				}
				finally
				{
					if (client != null)
					{
						((IDisposable)client).Dispose();
					}
				}
			}
			SaveIpIfValid();
			SetStatus("ADMIN READY / جاهز", success: true);
			Log("Admin service ready ✓");
			Log("Select JIGGYMODS - ADMIN EDIT inside the lobby menu now.");
		}
		catch (OperationCanceledException)
		{
		}
		catch (Exception ex3)
		{
			if (version == Volatile.Read(in operationVersion))
			{
				Fail(ex3.Message);
			}
		}
		finally
		{
			if (operationCts == nextCts)
			{
				operationCts = null;
			}
			nextCts.Dispose();
		}
	}

	private async Task QueueOneClickAsync(ConsoleTarget target)
	{
		int version = Interlocked.Increment(ref operationVersion);
		CancellationTokenSource nextCts = new CancellationTokenSource();
		CancellationTokenSource cancellationTokenSource = Interlocked.Exchange(ref operationCts, nextCts);
		if (cancellationTokenSource != null)
		{
			try
			{
				cancellationTokenSource.Cancel();
			}
			catch (ObjectDisposedException)
			{
			}
		}
		txtLog.Clear();
		Log("Connecting to " + ((target == ConsoleTarget.Ps5) ? "PS5" : "PS4") + "…");
		await Task.Run((Action)StopOldWatchers);
		try
		{
			await RunOneClickAsync(target, nextCts.Token, version);
		}
		finally
		{
			if (operationCts == nextCts)
			{
				operationCts = null;
			}
			nextCts.Dispose();
		}
	}

	private async Task RunOneClickAsync(ConsoleTarget target, CancellationToken cancellationToken, int version)
	{
		string ip = txtIp.Text.Trim();
		if (!IPAddress.TryParse(ip, out IPAddress _))
		{
			Fail("Invalid IP address / عنوان IP غير صحيح");
			return;
		}
		ResetStages();
		string text = ((target == ConsoleTarget.Ps5) ? "PS5" : "PS4");
		try
		{
			SetStatus("STARTING " + text + " / جاري التشغيل", success: false);
			SetStage(0, active: true);
			Log("Checking Debug…");
			await EnsureDebugAsync(ip, target, cancellationToken);
			await EnsureNexusAsync(ip, target, cancellationToken);
			CompleteStage(0);
			SetStage(1, active: true);
			Ps4DebugClient client = new Ps4DebugClient();
			try
			{
				await Task.Run(delegate
				{
					client.Connect(ip);
				}, cancellationToken);
				cancellationToken.ThrowIfCancellationRequested();
				TryNotify(client, "Easy Inject: Debug connected");
				if (await IsPortOpenAsync(ip, 2567, 400, cancellationToken))
				{
					TryNotify(client, "Easy Inject: Nexus connected");
				}
				CompleteStage(1);
				SetStage(2, active: true);
				(int, string) tuple = await Task.Run(() => ((int Pid, string Name))client.ListProcesses().FirstOrDefault<(int, string)>(((int Pid, string Name) p) => p.Name.Equals("codmp.elf", StringComparison.OrdinalIgnoreCase)), cancellationToken);
				cancellationToken.ThrowIfCancellationRequested();
				if (tuple.Item1 == 0)
				{
					throw new InvalidOperationException("BO2 codmp.elf was not found. Open CUSA57548 v1.10 and enter a LAN lobby.");
				}
				WriteDiagnostic($"Attached to codmp.elf (PID {tuple.Item1}).");
				Log("BO2 connected ✓");
				TryNotify(client, "Easy Inject: Attached to Black Ops II");
				CompleteStage(2);
			}
			finally
			{
				if (client != null)
				{
					((IDisposable)client).Dispose();
				}
			}
			SetStage(3, active: true);
			Log("Installing lobby menu…");
			StopOldWatchers();
			await RunLobbyToolAsync(ip, "--uninstall", allowFailure: true, cancellationToken);
			await RunLobbyToolAsync(ip, null, allowFailure: false, cancellationToken);
			await RunLobbyToolAsync(ip, "--enable-fps", allowFailure: false, cancellationToken);
			if (!(await RunLobbyToolAsync(ip, "--diagnose", allowFailure: false, cancellationToken)).Contains("BO2 LOBBY MENU", StringComparison.OrdinalIgnoreCase))
			{
				throw new InvalidOperationException("Lobby menu verification did not return the expected title.");
			}
			CompleteStage(3);
			Ps4DebugClient notificationClient = new Ps4DebugClient();
			try
			{
				await Task.Run(delegate
				{
					notificationClient.Connect(ip);
				}, cancellationToken);
				TryNotify(notificationClient, "Easy Inject: Lobby menu injected - L2 + L3");
			}
			finally
			{
				if (notificationClient != null)
				{
					((IDisposable)notificationClient).Dispose();
				}
			}
			SaveIpIfValid();
			SetStatus("READY — L2 + L3 / جاهز", success: true);
			Log("Lobby menu ready ✓");
			Log("L2 + L3 → Open menu  |  □ → Select");
		}
		catch (OperationCanceledException)
		{
		}
		catch (Exception ex2)
		{
			if (version == Volatile.Read(in operationVersion))
			{
				Fail(ex2.Message);
			}
		}
	}

	private async Task EnsureDebugAsync(string ip, ConsoleTarget target, CancellationToken cancellationToken)
	{
		if (await IsPortOpenAsync(ip, 744, 500, cancellationToken))
		{
			Log("Debug ready ✓");
			return;
		}
		string path = ((target == ConsoleTarget.Ps5) ? System.IO.Path.Combine("Payloads", "ps5debug-NG_v1.3.0.elf") : System.IO.Path.Combine("Payloads", "ps4debug.bin"));
		string payload = System.IO.Path.Combine(AppContext.BaseDirectory, path);
		if (!File.Exists(payload))
		{
			throw new FileNotFoundException("Bundled debug payload is missing.", payload);
		}
		int[] ports = ((target == ConsoleTarget.Ps5) ? Ps5LoaderPorts : Ps4LoaderPorts);
		int loaderPort = 0;
		Log("Looking for payload loader…");
		DateTime loaderDeadline = DateTime.UtcNow.AddSeconds((target == ConsoleTarget.Ps5) ? 15 : 4);
		do
		{
			cancellationToken.ThrowIfCancellationRequested();
			if (await IsPortOpenAsync(ip, 744, 500, cancellationToken))
			{
				Log("Debug ready ✓");
				return;
			}
			int[] array = ports;
			foreach (int port in array)
			{
				if (await IsPortOpenAsync(ip, port, 550, cancellationToken))
				{
					loaderPort = port;
					break;
				}
			}
			if (loaderPort == 0 && DateTime.UtcNow < loaderDeadline)
			{
				await Task.Delay(500, cancellationToken);
			}
		}
		while (loaderPort == 0 && DateTime.UtcNow < loaderDeadline);
		if (loaderPort == 0)
		{
			throw new InvalidOperationException((target == ConsoleTarget.Ps5) ? "PS5 Debug (744) and remote ELF Loader (9021/9020/9022) are unavailable. Enable ELF Loader in etaHEN, then press PS5 again. FTP alone cannot start a payload. / فع\u0651ل ELF Loader في etaHEN ثم اضغط PS5 مجدد\u064bا" : "Debug and BIN Loader are unavailable. Enable GoldHEN BIN Loader, then press PS4 again.");
		}
		WriteDiagnostic($"Sending {System.IO.Path.GetFileName(payload)} to port {loaderPort}...");
		Log("Sending Debug…");
		byte[] data = await File.ReadAllBytesAsync(payload);
		using (TcpClient tcp = new TcpClient())
		{
			await tcp.ConnectAsync(ip, loaderPort, cancellationToken).AsTask().WaitAsync(TimeSpan.FromSeconds(5.0), cancellationToken);
			using NetworkStream stream = tcp.GetStream();
			await stream.WriteAsync(data, cancellationToken).AsTask().WaitAsync(TimeSpan.FromSeconds(12.0), cancellationToken);
			await stream.FlushAsync(cancellationToken).WaitAsync(TimeSpan.FromSeconds(5.0), cancellationToken);
		}
		Log("Starting Debug…");
		DateTime deadline = DateTime.UtcNow.AddSeconds(18.0);
		while (DateTime.UtcNow < deadline)
		{
			if (await IsPortOpenAsync(ip, 744, 500, cancellationToken))
			{
				Log("Debug ready ✓");
				return;
			}
			await Task.Delay(350, cancellationToken);
		}
		throw new TimeoutException("Debug payload was sent, but port 744 did not open.");
	}

	private async Task EnsureNexusAsync(string ip, ConsoleTarget target, CancellationToken cancellationToken)
	{
		if (await IsPortOpenAsync(ip, 2567, 500, cancellationToken))
		{
			Log("Admin service ready ✓");
			return;
		}
		int[] array = ((target == ConsoleTarget.Ps5) ? Ps5LoaderPorts : Ps4LoaderPorts);
		int loaderPort = 0;
		int[] array2 = array;
		foreach (int port in array2)
		{
			if (await IsPortOpenAsync(ip, port, 500, cancellationToken))
			{
				loaderPort = port;
				break;
			}
		}
		if (loaderPort == 0)
		{
			Log("Admin needs Nexus: enable ELF Loader, then press ADMIN MENU SETUP.");
			return;
		}
		string text = ((target == ConsoleTarget.Ps5) ? "nexus-ps5.elf" : "nexus-ps4.elf");
		string text2 = System.IO.Path.Combine(AppContext.BaseDirectory, "Payloads", text);
		if (!File.Exists(text2))
		{
			throw new FileNotFoundException("Bundled Nexus payload is missing.", text2);
		}
		WriteDiagnostic($"Sending {text} to port {loaderPort}...");
		Log("Starting Admin service…");
		byte[] data = await File.ReadAllBytesAsync(text2, cancellationToken);
		using (TcpClient tcp = new TcpClient())
		{
			await tcp.ConnectAsync(ip, loaderPort, cancellationToken).AsTask().WaitAsync(TimeSpan.FromSeconds(5.0), cancellationToken);
			using NetworkStream stream = tcp.GetStream();
			await stream.WriteAsync(data, cancellationToken).AsTask().WaitAsync(TimeSpan.FromSeconds(12.0), cancellationToken);
			await stream.FlushAsync(cancellationToken).WaitAsync(TimeSpan.FromSeconds(5.0), cancellationToken);
		}
		DateTime deadline = DateTime.UtcNow.AddSeconds(15.0);
		while (DateTime.UtcNow < deadline)
		{
			if (await IsPortOpenAsync(ip, 2567, 500, cancellationToken))
			{
				Log("Admin service ready ✓");
				return;
			}
			await Task.Delay(350, cancellationToken);
		}
		Log("Admin unavailable: Nexus did not start. Retry ADMIN MENU SETUP.");
	}

	private static async Task<bool> IsPortOpenAsync(string host, int port, int timeoutMs, CancellationToken cancellationToken)
	{
		try
		{
			using TcpClient tcp = new TcpClient();
			await tcp.ConnectAsync(host, port, cancellationToken).AsTask().WaitAsync(TimeSpan.FromMilliseconds((double)timeoutMs), cancellationToken);
			return tcp.Connected;
		}
		catch (OperationCanceledException)
		{
			throw;
		}
		catch
		{
			return false;
		}
	}

	private async Task<string> RunLobbyToolAsync(string ip, string? operation = null, bool allowFailure = false, CancellationToken cancellationToken = default(CancellationToken))
	{
		string text = System.IO.Path.Combine(AppContext.BaseDirectory, "Lobby", "EasyInject.Lobby.exe");
		if (!File.Exists(text))
		{
			throw new FileNotFoundException("Lobby injector helper is missing.", text);
		}
		ProcessStartInfo processStartInfo = new ProcessStartInfo(text)
		{
			UseShellExecute = false,
			CreateNoWindow = true,
			RedirectStandardOutput = true,
			RedirectStandardError = true,
			WorkingDirectory = System.IO.Path.GetDirectoryName(text)
		};
		processStartInfo.ArgumentList.Add("--host");
		processStartInfo.ArgumentList.Add(ip);
		if (!string.IsNullOrWhiteSpace(operation))
		{
			processStartInfo.ArgumentList.Add(operation);
		}
		using Process process = Process.Start(processStartInfo) ?? throw new InvalidOperationException("Could not start the lobby injector.");
		Task<string> stdout = process.StandardOutput.ReadToEndAsync();
		Task<string> stderr = process.StandardError.ReadToEndAsync();
		try
		{
			await process.WaitForExitAsync(cancellationToken).WaitAsync(TimeSpan.FromSeconds(40.0), cancellationToken);
		}
		catch
		{
			try
			{
				if (!process.HasExited)
				{
					process.Kill(entireProcessTree: true);
				}
			}
			catch
			{
			}
			throw;
		}
		string output = (await stdout).Trim();
		string text2 = (await stderr).Trim();
		if (!string.IsNullOrWhiteSpace(output))
		{
			string[] array = output.Split(new char[2] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
			for (int i = 0; i < array.Length; i++)
			{
				WriteDiagnostic(array[i]);
			}
		}
		if (!string.IsNullOrWhiteSpace(text2))
		{
			WriteDiagnostic(text2);
		}
		if (process.ExitCode != 0 && !allowFailure)
		{
			throw new InvalidOperationException(string.IsNullOrWhiteSpace(text2) ? $"Lobby injector failed ({process.ExitCode})." : text2);
		}
		return output + Environment.NewLine + text2;
	}

	private static void StopOldWatchers()
	{
		string[] array = new string[2] { "EasyInject.Lobby", "BO2NativeLobbyMenu" };
		for (int i = 0; i < array.Length; i++)
		{
			Process[] processesByName = Process.GetProcessesByName(array[i]);
			foreach (Process process in processesByName)
			{
				try
				{
					process.Kill(entireProcessTree: true);
					process.WaitForExit(1500);
				}
				catch
				{
				}
				finally
				{
					process.Dispose();
				}
			}
		}
	}

	private static void TryNotify(Ps4DebugClient client, string message)
	{
		try
		{
			client.Notify(message);
		}
		catch
		{
		}
	}

	private void ResetStages()
	{
	}

	private void SetStage(int index, bool active)
	{
		string[] array = new string[4] { "DEBUG", "CONNECT", "ATTACH", "LOBBY MENU" };
		if (active)
		{
			SetStatus(array[index], success: false);
		}
	}

	private void CompleteStage(int index)
	{
		string[] array = new string[4] { "DEBUG OK", "CONNECTED", "ATTACHED", "LOBBY MENU READY" };
		SetStatus(array[index], index == array.Length - 1);
	}

	private void SetStatus(string text, bool success)
	{
		lblStatus.Text = text;
		dot.Fill = (success ? doneBrush : activeBrush);
	}

	private void Fail(string message)
	{
		lblStatus.Text = "FAILED / فشل";
		dot.Fill = new SolidColorBrush(Color.FromRgb(byte.MaxValue, 92, 105));
		WriteDiagnostic("ERROR: " + message);
		string text = message.Split(new char[2] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries).FirstOrDefault() ?? "Connection failed. Please retry.";
		Log("Error: " + text);
	}

	private void Log(string message)
	{
		txtLog.AppendText(message + Environment.NewLine);
		txtLog.ScrollToEnd();
		WriteDiagnostic(message);
	}

	private static void WriteDiagnostic(string message)
	{
		string contents = $"[{DateTime.Now:HH:mm:ss}] {message}{Environment.NewLine}";
		try
		{
			string? directoryName = System.IO.Path.GetDirectoryName(SettingsFile);
			Directory.CreateDirectory(directoryName);
			File.AppendAllText(System.IO.Path.Combine(directoryName, "connection.log"), contents);
		}
		catch
		{
		}
	}

	private void LoadSavedIp()
	{
		string text = System.IO.Path.Combine(AppContext.BaseDirectory, "easyinject-ip.txt");
		string path = (File.Exists(SettingsFile) ? SettingsFile : text);
		try
		{
			if (File.Exists(path))
			{
				string text2 = File.ReadAllText(path).Trim();
				if (IPAddress.TryParse(text2, out IPAddress _))
				{
					txtIp.Text = text2;
				}
			}
		}
		catch
		{
		}
	}

	private void SaveIpIfValid()
	{
		string text = txtIp.Text.Trim();
		if (!IPAddress.TryParse(text, out IPAddress _))
		{
			return;
		}
		try
		{
			string directoryName = System.IO.Path.GetDirectoryName(SettingsFile);
			if (!string.IsNullOrWhiteSpace(directoryName))
			{
				Directory.CreateDirectory(directoryName);
			}
			File.WriteAllText(SettingsFile, text);
		}
		catch
		{
		}
	}

	[DebuggerNonUserCode]
	[GeneratedCode("PresentationBuildTasks", "9.0.7.0")]
	public void InitializeComponent()
	{
		if (!_contentLoaded)
		{
			_contentLoaded = true;
			Uri resourceLocator = new Uri("/EasyInject;component/mainwindow.xaml", UriKind.Relative);
			Application.LoadComponent(this, resourceLocator);
		}
	}

	[DebuggerNonUserCode]
	[GeneratedCode("PresentationBuildTasks", "9.0.7.0")]
	[EditorBrowsable(EditorBrowsableState.Never)]
	void IComponentConnector.Connect(int connectionId, object target)
	{
		switch (connectionId)
		{
		case 1:
			dot = (Ellipse)target;
			break;
		case 2:
			lblStatus = (TextBlock)target;
			break;
		case 3:
			txtIp = (TextBox)target;
			break;
		case 4:
			btnPs4OneClick = (Button)target;
			break;
		case 5:
			btnPs5OneClick = (Button)target;
			break;
		case 6:
			btnAdminSetup = (Button)target;
			break;
		case 7:
			txtLog = (TextBox)target;
			break;
		default:
			_contentLoaded = true;
			break;
		}
	}
}
public static class Program
{
	[STAThread]
	public static void Main()
	{
		new Application().Run(new MainWindow());
	}
}
