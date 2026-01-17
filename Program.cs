using System.Diagnostics;
using System.Runtime.InteropServices;
]
namespace TimeoutCommand
{
    public class Program
    {
        // Exit codes compatible with GNU timeout
        private const int ExitTimeout = 124;
        private const int ExitTimeoutFailure = 125;
        private const int ExitCommandNotExecutable = 126;
        private const int ExitCommandNotFound = 127;
        private const int ExitKilledByKillSignal = 137;

        // Signal constants for Unix systems
        private const int SIGTERM = 15;
        private const int SIGKILL = 9;
        private const int SIGINT = 2;
        private const int SIGHUP = 1;
        private const int SIGUSR1 = 10;
        private const int SIGUSR2 = 12;

        public static async Task<int> Main(string[] args)
        {
            try
            {
                var options = ParseArgs(args);
                
                if (options.Help)
                {
                    ShowHelp();
                    return 0;
                }
                
                if (options.Version)
                {
                    ShowVersion();
                    return 0;
                }

                if (string.IsNullOrEmpty(options.Duration))
                {
                    Console.Error.WriteLine("missing operand");
                    Console.Error.WriteLine("Try '--help' for more information.");
                    return ExitTimeoutFailure;
                }

                if (string.IsNullOrEmpty(options.Command))
                {
                    Console.Error.WriteLine("missing command");
                    Console.Error.WriteLine("Try '--help' for more information.");
                    return ExitTimeoutFailure;
                }

                return await RunTimeout(options);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine(ex.Message);
                return ExitTimeoutFailure;
            }
        }

        private static TimeoutOptions ParseArgs(string[] args)
        {
            var options = new TimeoutOptions();
            var i = 0;

            while (i < args.Length)
            {
                var arg = args[i];

                if (arg == "--help")
                {
                    options.Help = true;
                    return options;
                }
                else if (arg == "--version")
                {
                    options.Version = true;
                    return options;
                }
                else if (arg == "-f" || arg == "--foreground")
                {
                    options.Foreground = true;
                }
                else if (arg == "-k" || arg == "--kill-after")
                {
                    if (i + 1 >= args.Length)
                        throw new ArgumentException("option requires an argument -- k");
                    options.KillAfter = args[++i];
                }
                else if (arg == "-p" || arg == "--preserve-status")
                {
                    options.PreserveStatus = true;
                }
                else if (arg == "-s" || arg == "--signal")
                {
                    if (i + 1 >= args.Length)
                        throw new ArgumentException("option requires an argument -- s");
                    options.Signal = args[++i];
                }
                else if (arg == "-v" || arg == "--verbose")
                {
                    options.Verbose = true;
                }
                else if (arg.StartsWith("-"))
                {
                    throw new ArgumentException($"invalid option -- '{arg}'");
                }
                else
                {
                    // First non-option argument is duration
                    if (string.IsNullOrEmpty(options.Duration))
                    {
                        options.Duration = arg;
                    }
                    // Second non-option argument is command
                    else if (string.IsNullOrEmpty(options.Command))
                    {
                        options.Command = arg;
                    }
                    // Remaining arguments are command arguments
                    else
                    {
                        options.Arguments.Add(arg);
                    }
                }
                i++;
            }

            return options;
        }

        private static TimeSpan ParseDuration(string duration)
        {
            if (string.IsNullOrEmpty(duration))
                throw new ArgumentException("Invalid duration");

            var value = duration;
            var unit = "";

            // Extract numeric part and unit
            var i = 0;
            while (i < duration.Length && (char.IsDigit(duration[i]) || duration[i] == '.'))
            {
                i++;
            }

            if (i == 0)
                throw new ArgumentException($"invalid time interval: '{duration}'");

            value = duration.Substring(0, i);
            if (i < duration.Length)
                unit = duration.Substring(i);

            if (!double.TryParse(value, out double numValue))
                throw new ArgumentException($"invalid time interval: '{duration}'");

            return unit.ToLower() switch
            {
                "ms" => TimeSpan.FromMilliseconds(numValue),
                "s" or "" => TimeSpan.FromSeconds(numValue),
                "m" => TimeSpan.FromMinutes(numValue),
                "h" => TimeSpan.FromHours(numValue),
                "d" => TimeSpan.FromDays(numValue),
                _ => throw new ArgumentException($"invalid time interval: '{duration}'")
            };
        }

        private static int ParseSignal(string signal)
        {
            return signal.ToUpper() switch
            {
                "TERM" => SIGTERM,
                "KILL" => SIGKILL,
                "INT" => SIGINT,
                "HUP" => SIGHUP,
                "USR1" => SIGUSR1,
                "USR2" => SIGUSR2,
                _ when int.TryParse(signal, out int sigNum) => sigNum,
                _ => throw new ArgumentException($"invalid signal: '{signal}'")
            };
        }

        private static async Task<int> RunTimeout(TimeoutOptions options)
        {
            var timeout = ParseDuration(options.Duration);
            TimeSpan? killAfter = null;
            if (!string.IsNullOrEmpty(options.KillAfter))
            {
                killAfter = ParseDuration(options.KillAfter);
            }

            var signal = SIGTERM;
            if (!string.IsNullOrEmpty(options.Signal))
            {
                signal = ParseSignal(options.Signal);
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = options.Command,
                Arguments = string.Join(" ", options.Arguments),
                UseShellExecute = false
            };

            if (!options.Foreground)
            {
                startInfo.RedirectStandardInput = true;
                startInfo.RedirectStandardOutput = true;
                startInfo.RedirectStandardError = true;
            }

            Process? process;
            try
            {
                process = Process.Start(startInfo);
                if (process == null)
                {
                    Console.Error.WriteLine($"timeout: failed to run command '{options.Command}': No such file or directory");
                    return ExitCommandNotFound;
                }
            }
            catch (System.ComponentModel.Win32Exception ex)
            {
                if (ex.NativeErrorCode == 2) // File not found
                {
                    Console.Error.WriteLine($"timeout: failed to run command '{options.Command}': No such file or directory");
                    return ExitCommandNotFound;
                }
                else if (ex.NativeErrorCode == 5) // Access denied
                {
                    Console.Error.WriteLine($"timeout: failed to run command '{options.Command}': Permission denied");
                    return ExitCommandNotExecutable;
                }
                else
                {
                    Console.Error.WriteLine($"timeout: failed to run command '{options.Command}': {ex.Message}");
                    return ExitTimeoutFailure;
                }
            }

            var timeoutOccurred = false;
            var cts = new CancellationTokenSource();

            // Start timeout timer
            var timeoutTask = Task.Delay(timeout, cts.Token).ContinueWith(async _ =>
            {
                if (!cts.Token.IsCancellationRequested)
                {
                    timeoutOccurred = true;
                    
                    if (options.Verbose)
                    {
                        Console.Error.WriteLine($"timeout: sending signal {GetSignalName(signal)} to process {process.Id}");
                    }

                    try
                    {
                        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                        {
                            // On Windows, we can only terminate forcefully
                            process.Kill(entireProcessTree: true);
                        }
                        else
                        {
                            // On Unix systems, send the specified signal
                            SendSignal(process.Id, signal);
                        }
                    }
                    catch (Exception ex)
                    {
                        if (options.Verbose)
                        {
                            Console.Error.WriteLine($"timeout: failed to send signal: {ex.Message}");
                        }
                    }

                    // If kill-after is specified, wait and then send KILL
                    if (killAfter.HasValue)
                    {
                        await Task.Delay(killAfter.Value);
                        if (!process.HasExited)
                        {
                            if (options.Verbose)
                            {
                                Console.Error.WriteLine($"timeout: sending signal KILL to process {process.Id}");
                            }

                            try
                            {
                                if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                                {
                                    process.Kill(entireProcessTree: true);
                                }
                                else
                                {
                                    SendSignal(process.Id, SIGKILL);
                                }
                            }
                            catch (Exception ex)
                            {
                                if (options.Verbose)
                                {
                                    Console.Error.WriteLine($"timeout: failed to send KILL signal: {ex.Message}");
                                }
                            }
                        }
                    }
                }
            }, TaskScheduler.Default).Unwrap();

            // Wait for process to exit
            await process.WaitForExitAsync();
            cts.Cancel();

            // Handle the result
            if (timeoutOccurred)
            {
                if (options.PreserveStatus)
                {
                    return process.ExitCode;
                }
                else
                {
                    return ExitTimeout;
                }
            }
            else
            {
                return process.ExitCode;
            }
        }

        private static void SendSignal(int processId, int signal)
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                // Windows doesn't support Unix signals, so we just terminate
                try
                {
                    var process = Process.GetProcessById(processId);
                    process.Kill();
                }
                catch
                {
                    // Process may have already exited
                }
            }
            else
            {
                // Use kill system call on Unix systems
                kill(processId, signal);
            }
        }

        private static string GetSignalName(int signal)
        {
            return signal switch
            {
                SIGTERM => "TERM",
                SIGKILL => "KILL",
                SIGINT => "INT",
                SIGHUP => "HUP",
                SIGUSR1 => "USR1",
                SIGUSR2 => "USR2",
                _ => signal.ToString()
            };
        }

        [DllImport("libc", SetLastError = true)]
        private static extern int kill(int pid, int sig);

        private static void ShowHelp()
        {
            Console.WriteLine("Usage: timeout [OPTION] DURATION COMMAND [ARG]...");
            Console.WriteLine("  or:  timeout [OPTION]");
            Console.WriteLine("Start COMMAND, and kill it if still running after DURATION.");
            Console.WriteLine();
            Console.WriteLine("Mandatory arguments to long options are mandatory for short options too.");
            Console.WriteLine("  -f, --foreground      allow COMMAND to read from TTY and get TTY signals");
            Console.WriteLine("  -k, --kill-after=DURATION");
            Console.WriteLine("                        also send KILL signal after DURATION");
            Console.WriteLine("  -p, --preserve-status exit with same status as COMMAND");
            Console.WriteLine("  -s, --signal=SIGNAL   specify signal to send on timeout");
            Console.WriteLine("  -v, --verbose         diagnose to stderr any signal sent");
            Console.WriteLine("      --help            display this help and exit");
            Console.WriteLine("      --version         output version information and exit");
            Console.WriteLine();
            Console.WriteLine("DURATION is a floating point number with an optional suffix:");
            Console.WriteLine("'s' for seconds (the default), 'm' for minutes, 'h' for hours or 'd' for days.");
            Console.WriteLine("A duration of 0 disables the associated timeout.");
            Console.WriteLine();
            Console.WriteLine("If the command times out, and --preserve-status is not set, then exit with");
            Console.WriteLine("status 124.  Otherwise, exit with the status of COMMAND.  If no signal");
            Console.WriteLine("is specified, send the TERM signal upon timeout.  The TERM signal kills");
            Console.WriteLine("any process that does not block or catch that signal.  It may be necessary");
            Console.WriteLine("to use the KILL (9) signal, since this signal cannot be caught, in which");
            Console.WriteLine("case the exit status is 128+9 rather than 124.");
        }

        private static void ShowVersion()
        {
            Console.WriteLine("timeout (C# implementation) 1.0.0");
            Console.WriteLine("Copyright (C) 2026 Stephen Gennard <stephen@gennard.net>");
            Console.WriteLine("GitHub: https://github.com/spgennard/cs-timeout");
        }
    }

    public class TimeoutOptions
    {
        public bool Foreground { get; set; } = false;
        public string? KillAfter { get; set; }
        public bool PreserveStatus { get; set; } = false;
        public string? Signal { get; set; }
        public bool Verbose { get; set; } = false;
        public bool Help { get; set; } = false;
        public bool Version { get; set; } = false;
        public string Duration { get; set; } = "";
        public string Command { get; set; } = "";
        public List<string> Arguments { get; set; } = new();
    }
}