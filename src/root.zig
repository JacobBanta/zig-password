const std = @import("std");
const os = std.os;
const builtin = @import("builtin");
const kernel = std.os.windows.kernel32;

var stdout: @TypeOf(std.io.getStdOut().handle) = undefined;
var stdin: @TypeOf(std.io.getStdIn().handle) = undefined;

const terminal = struct {
    var wflags: std.os.windows.DWORD = 0;
    var lflags: os.linux.termios = undefined;
    extern "kernel32" fn SetConsoleMode(in_hConsoleHandle: std.os.windows.HANDLE, in_dwMode: std.os.windows.DWORD) callconv(std.os.windows.WINAPI) std.os.windows.BOOL;
    fn clearColor() void {
        if (builtin.os.tag == .windows) {
            _ = kernel.SetConsoleTextAttribute(stdout, 7);
        } else {
            std.debug.print("{c}[0m", .{27});
        }
    }
    fn redBg() void {
        if (builtin.os.tag == .windows) {
            _ = kernel.SetConsoleTextAttribute(stdout, 71);
        } else {
            std.debug.print("{c}[41m", .{27});
        }
    }
    fn redFg() void {
        if (builtin.os.tag == .windows) {
            _ = kernel.SetConsoleTextAttribute(stdout, 4);
        } else {
            std.debug.print("{c}[91m", .{27});
        }
    }
    fn getTermFlags() !void {
        if (builtin.os.tag == .windows) {
            _ = kernel.GetConsoleMode(stdin, &wflags);
        } else {
            _ = os.linux.tcgetattr(os.STDIN_FILENO, &lflags);
        }
    }
    fn setTermFlags() !void {
        if (builtin.os.tag == .windows) {
            _ = terminal.SetConsoleMode(stdin, wflags & 0xfffffff9);
        } else {
            var newFlags = lflags;
            newFlags.lflag &= 0xFFFFFFF5;

            _ = os.linux.tcsetattr(os.STDIN_FILENO, .NOW, &newFlags);
        }
    }

    fn resetTermFlags() !void {
        if (builtin.os.tag == .windows) {
            _ = terminal.SetConsoleMode(stdin, wflags);
        } else {
            _ = os.linux.tcsetattr(os.STDIN_FILENO, .NOW, &lflags);
        }
    }
};

pub fn getPassword(comptime options: struct {
    minLen: u8 = 6,
    maxLen: u8 = 16,
    defaultErrHandleing: bool = true,
}) ![options.maxLen]u8 {
    var buffer = [_]u8{0} ** options.maxLen;
    try init();
    defer deinit() catch unreachable;
    if (options.defaultErrHandleing) {
        var i: usize = 0;
        while (true) {
            const input = std.io.getStdIn().reader().readByte() catch continue;
            if ((input == 10 or input == 13) and i <= options.maxLen and i >= options.minLen) break;
            if ((input == 10 or input == 13) and i < options.minLen) {
                terminal.redFg();
                for (0..options.minLen - i) |_| {
                    std.debug.print("*", .{});
                }
                terminal.clearColor();
                for (0..options.minLen - i) |_| {
                    std.debug.print("{c}", .{8});
                }
                continue;
            }
            if (input == 10 or input == 13) continue;
            if ((input == 127 or input == 8) and i > 0) {
                if (i < options.maxLen)
                    buffer[i] = 0;
                i -= 1;
                std.debug.print("{c} {c}", .{ 8, 8 });
                continue;
            }
            if (input == 27) {
                continue;
            }
            if (input == 127) continue;
            if (i >= options.maxLen) {
                terminal.redBg();
                std.debug.print("*", .{});
                terminal.clearColor();
                i += 1;
                continue;
            }
            buffer[i] = input;
            std.debug.print("*", .{});
            i += 1;
        }
        return buffer;
    } else {
        var i: usize = 0;
        while (true) {
            const input = std.io.getStdIn().reader().readByte() catch continue;
            if ((input == 10 or input == 13) and i < options.maxLen and i >= options.minLen) break;
            if ((input == 10 or input == 13) and i < options.minLen) {
                return error.tooShort;
            }
            if (input == 10 or input == 13) return error.tooLong;
            if ((input == 127 or input == 8) and i >= 0) {
                if (i < options.maxLen)
                    buffer[i] = 0;
                if (i > 0)
                    i -= 1;
                std.debug.print("{c} {c}", .{ 8, 8 });
                continue;
            }
            if (input == 127 or input == 8) continue;
            if (i >= options.maxLen) {
                std.debug.print("*", .{});
                continue;
            }
            buffer[i] = input;
            std.debug.print("*", .{});
            i += 1;
        }
        return buffer;
    }
}

fn init() !void {
    if (builtin.os.tag != .windows and builtin.os.tag != .linux)
        @compileError("os not supported");
    stdin = std.io.getStdIn().handle;
    stdout = std.io.getStdOut().handle;
    try terminal.getTermFlags();
    try terminal.setTermFlags();
}

fn deinit() !void {
    try terminal.resetTermFlags();
}
