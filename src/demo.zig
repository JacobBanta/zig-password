const std = @import("std");
const password = @import("root.zig");

pub fn main() !void {
    std.debug.print("Password: ", .{});
    const pass = try password.getPassword(.{});
    std.debug.print("\nYour password is: {s}\n", .{pass});
}
