const std = @import("std");
const os = std.os;
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

var flags: os.termios = undefined;

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
            if (input == 10 and i < options.maxLen and i >= options.minLen) break;
            if (input == 10 and i < options.minLen) {
                for (0..options.minLen - i) |_| {
                    std.debug.print("{c}[91m*{c}[0m", .{ 27, 27 });
                }
                for (0..options.minLen - i) |_| {
                    std.debug.print("{c}", .{8});
                }
                continue;
            }
            if (input == 10) continue;
            if (input == 127 and i >= 0) {
                if (i < options.maxLen)
                    buffer[i] = 0;
                if (i > 0)
                    i -= 1;
                std.debug.print("{c} {c}", .{ 8, 8 });
                continue;
            }
            if (input == 27) {
                continue;
            }
            if (input == 127) continue;
            if (i >= options.maxLen) {
                std.debug.print("{c}[41m*{c}[0m", .{ 27, 27 });
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
            if (input == 10 and i < options.maxLen and i >= options.minLen) break;
            if (input == 10 and i < options.minLen) {
                return error.tooShort;
            }
            if (input == 10) return error.tooLong;
            if (input == 127 and i >= 0) {
                if (i < options.maxLen)
                    buffer[i] = 0;
                if (i > 0)
                    i -= 1;
                std.debug.print("{c} {c}", .{ 8, 8 });
                continue;
            }
            if (input == 127) continue;
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

fn getTermFlags() !void {
    flags = os.tcgetattr(os.STDIN_FILENO) catch |err| {
        return err;
    };
}

fn setTermFlags() !void {
    var newFlags = flags;
    newFlags.lflag &= 0xFFFFFFF5;

    os.tcsetattr(os.STDIN_FILENO, .NOW, newFlags) catch |err| {
        return err;
    };
}

fn resetTermFlags() !void {
    os.tcsetattr(os.STDIN_FILENO, .NOW, flags) catch |err| {
        return err;
    };
}

fn init() !void {
    try getTermFlags();
    try setTermFlags();
}

fn deinit() !void {
    try resetTermFlags();
}
