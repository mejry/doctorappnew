// services/authService.js
const crypto = require("crypto");
const User = require("../models/User");
const Role = require("../models/Role");
const jwtUtil = require("../utils/jwt");
const emailUtil = require("../utils/email");
const logger = require("../utils/logger");
const { rabbitMQ } = require("../utils/rabbitmq");
const { log } = require("console");
const bcrypt = require("bcryptjs");
const rabbitmq = require("../utils/rabbitmq");

// Authentication service
module.exports = {
  /**
   * User login - FIXED
   */
async login(email, password, req) {
    try {
      // Input validation
      if (!email || !password) {
        console.log("Missing email or password");
        throw new Error("Email and password required");
      }

      console.log("Login attempt for:", email);

      // Find user and populate role
      const user = await User.findOne({ email }).populate("role").populate("additionalRoles");
      
      if (!user || !user.active) {
        await logger.auth("LOGIN_FAILED", null, "Invalid credentials", req, { email });
        throw new Error("Invalid credentials");
      }

      if (!user.role) {
        console.error("User found but role is null:", user._id);
        await logger.auth("LOGIN_FAILED", user._id, "User has no role assigned", req);
        throw new Error("User account configuration error - no role assigned");
      }

      console.log("Found user:", user._id);
      console.log("User role:", user.role);

      // Password verification
      const isMatch = await bcrypt.compare(password, user.password);
      console.log("Password match:", isMatch);

      if (!isMatch) {
        await logger.auth("LOGIN_FAILED", user._id, "Invalid password", req);
        throw new Error("Invalid credentials");
      }

      // Log login attempt
      await logger.auth("LOGIN_ATTEMPT", user._id, "Login attempt", req);

      // ✅ FORCER 2FA TOUJOURS (pour les tests)
      console.log("🔍 2FA Configuration:");
      console.log("   - User 2FA enabled:", user.twoFactorEnabled);
      console.log("   - FORCING 2FA FOR ALL USERS (test mode)");
      
      // ✅ IMPORTANT: TOUJOURS retourner twoFactorRequired=true
      console.log("📱 2FA REQUIRED - Generating and sending code");
      
      // Generate 2FA code
      const code = crypto.randomInt(100000, 999999).toString();
      user.twoFactorCode = code;
      user.twoFactorExpires = new Date(Date.now() + 600000); // 10 minutes
      await user.save();

      // Send 2FA code via email
      try {
        await emailUtil.sendTemplatedEmail(email, "twoFactorCode", code);
        console.log("✅ 2FA code sent successfully to:", email);
        console.log("📧 CODE FOR TESTING:", code); // ✅ Pour débugger
      } catch (emailError) {
        console.error("❌ Failed to send 2FA email:", emailError);
        throw new Error("Failed to send verification code. Please try again.");
      }

      await logger.auth("2FA_SENT", user._id, "2FA code sent", req);

      // ✅ RETOURNER SEULEMENT twoFactorRequired, PAS DE TOKENS
      console.log("📱 Returning 2FA required response (NO TOKENS)");
      return { 
        twoFactorRequired: true, 
        userId: user._id,
        message: "2FA verification code sent to your email"
      };

    } catch (error) {
      console.error("Login error:", error);
      throw error;
    }
  },


  /**
   * User registration - FIXED
   */
  async register(userData, req) {
    try {
      console.log("Registration attempt for:", userData.email);
      console.log("Role requested:", userData.role);

      // Validate required fields
      const requiredFields = ["email", "password", "firstname", "lastname", "role"];
      const missingFields = requiredFields.filter((field) => !userData[field]);

      if (missingFields.length > 0) {
        throw new Error(`Missing fields: ${missingFields.join(", ")}`);
      }

      // FIXED: Role validation - lookup by name with error handling
      const role = await Role.findOne({ name: userData.role });
      if (!role) {
        console.error("Role not found:", userData.role);
        const availableRoles = await Role.find({}, 'name');
        console.log("Available roles:", availableRoles.map(r => r.name));
        throw new Error(`Invalid role: ${userData.role}. Available roles: ${availableRoles.map(r => r.name).join(', ')}`);
      }

      console.log("Role found:", role);

      // Specialty validation for doctors
      if (userData.role === "Doctor" && !userData.specialite) {
        throw new Error("Specialty required for doctors");
      }

      // Check if email already exists
      const existingUser = await User.findOne({ email: userData.email });
      if (existingUser) {
        throw new Error("Email already registered");
      }

      // FIXED: Create user with proper role assignment
      const user = new User({
        ...userData,
        role: role._id, // Assign the role ObjectId
        emailVerified: false,
      });

      await user.save();
      console.log("User created:", user._id);

      // Log registration
      await logger.auth("REGISTER", user._id, `Registered as ${userData.role}`, req);

      // Send welcome email
      try {
        await emailUtil.sendTemplatedEmail(userData.email, "welcome", user);
        // Email was sent successfully, mark email as verified
        user.emailVerified = true;
        await user.save();
        await logger.auth("EMAIL_VERIFIED", user._id, "Email verified on registration", req);
      } catch (error) {
        console.error("Failed to send welcome email:", error);
        // Don't fail registration if email fails
      }

      // FIXED: Notify other services with proper error handling
      try {
        await rabbitmq.sendMessage("user-service", {
          type: "user.created",
          userId: user._id,
          role: role.name,
          email: user.email,
          name: `${user.firstname} ${user.lastname}`,
        });
        console.log("User creation event sent to RabbitMQ");
      } catch (mqError) {
        console.error("Failed to send user creation event:", mqError.message);
        // Don't fail registration if RabbitMQ fails
      }

      // FIXED: Get fresh user data with populated role
      const updatedUser = await User.findById(user._id).populate("role");
      return updatedUser.toJSON();
    } catch (error) {
      console.error("Registration error:", error);
      throw error;
    }
  },

  /**
   * Verify 2FA - FIXED
   */
 async verify2FA(userId, code, req) {
    try {
      console.log("🔢 Verifying 2FA for user:", userId, "with code:", code);
      
      const user = await User.findOne({
        _id: userId,
        twoFactorCode: code,
        twoFactorExpires: { $gt: Date.now() },
      }).populate("role").populate("additionalRoles");

      if (!user) {
        console.log("❌ Invalid 2FA code or expired");
        await logger.auth("2FA_FAILED", userId, "Invalid 2FA code", req);
        throw new Error("Invalid or expired code");
      }

      if (!user.role) {
        throw new Error("User account configuration error - no role assigned");
      }

      console.log("✅ 2FA code verified successfully");

      // Clear 2FA code
      user.twoFactorCode = undefined;
      user.twoFactorExpires = undefined;
      user.lastLogin = new Date();
      await user.save();

      // Generate tokens
      const tokenPayload = {
        id: user._id,
        userId: user._id,
        email: user.email,
        firstname: user.firstname,
        lastname: user.lastname,
        specialite: user.specialite,
        role: user.role.name,
        permissions: user.role.permissions || [],
        iat: Math.floor(Date.now() / 1000)
      };

      const accessToken = jwtUtil.generateAccessToken(tokenPayload);
      const refreshToken = jwtUtil.generateRefreshToken(user._id);

      const serviceToken = jwtUtil.generateServiceToken({
        id: user._id,
        userId: user._id,
        email: user.email,
        firstname: user.firstname,
        lastname: user.lastname,
        specialite: user.specialite,
        role: user.role.name,
        permissions: user.role.permissions || [],
        service: "auth-service",
        timestamp: new Date().toISOString()
      });

      await logger.auth("2FA_VERIFIED", user._id, "2FA verified, login successful", req);

      // Send to RabbitMQ
      try {
        await rabbitmq.sendMessage("auth-tokens", {
          type: "token.issued",
          token: serviceToken,
          userId: user._id.toString(),
          userRole: user.role.name,
          userPermissions: user.role.permissions || [],
          action: "login_2fa",
          timestamp: new Date().toISOString()
        });
      } catch (mqError) {
        console.error("Failed to send token to RabbitMQ:", mqError.message);
      }

      console.log("✅ 2FA verification complete - returning tokens");
      return {
        accessToken,
        refreshToken,
        serviceToken,
        user: user.toJSON(),
        expiresIn: 900,
      };
    } catch (error) {
      console.error("2FA verification error:", error);
      throw error;
    }
  },
  

  /**
   * Refresh token - FIXED
   */
  async refreshToken(refreshToken) {
    try {
      if (!refreshToken) {
        throw new Error("Refresh token required");
      }

      const decoded = jwtUtil.verifyRefreshToken(refreshToken);
      
      // FIXED: Get user with populated role
      const user = await User.findById(decoded.id).populate("role");
      
      if (!user || !user.active) {
        throw new Error("Invalid refresh token");
      }

      // FIXED: Check if role exists
      if (!user.role) {
        throw new Error("User account configuration error - no role assigned");
      }

      // Generate new tokens
      const tokenPayload = {
        id: user._id,
        userId: user._id,
        email: user.email,
        role: user.role.name,
        permissions: user.role.permissions || [],
        iat: Math.floor(Date.now() / 1000)
      };

      const accessToken = jwtUtil.generateAccessToken(tokenPayload);

      // Generate new service token
      const serviceToken = jwtUtil.generateServiceToken({
        id: user._id,
        userId: user._id,
        email: user.email,
        role: user.role.name,
        permissions: user.role.permissions || [],
        service: 'auth-service',
        timestamp: new Date().toISOString()
      });

      // Send to RabbitMQ with error handling
      try {
        await rabbitmq.sendMessage('auth-tokens', {
          type: 'token.refreshed',
          token: serviceToken,
          userId: user._id.toString(),
          userRole: user.role.name,
          userPermissions: user.role.permissions || [],
          action: 'refresh',
          timestamp: new Date().toISOString()
        });
      } catch (mqError) {
        console.error("Failed to send refresh token to RabbitMQ:", mqError.message);
      }

      return {
        accessToken,
        serviceToken,
        expiresIn: 900
      };
    } catch (error) {
      console.error("Refresh token error:", error);
      throw error;
    }
  }, 
  /**
   * Send 2FA code
   * @param {String} email - User email
   * @param {Object} req - Express request object
   */
  async send2FACode(email, req) {
    const user = await User.findOne({ email });
    if (!user) {
      throw new Error("User not found");
    }

    // Generate 2FA code
    const code = crypto.randomInt(100000, 999999).toString();
    user.twoFactorCode = code;
    user.twoFactorExpires = new Date(Date.now() + 600000); // 10 minutes
    await user.save();

    // Send 2FA code via email
    await emailUtil.sendTemplatedEmail(email, "twoFactorCode", code);

    // Log 2FA code sent
    await logger.auth("2FA_SENT", user._id, "2FA code sent", req);
  },

  /**
   * Toggle 2FA for a user
   * @param {String} userId - User ID
   * @param {Boolean} enable - Enable or disable 2FA
   * @param {Object} req - Express request object
   * @returns {Object} Updated user
   */
  async toggle2FA(userId, enable, req) {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error("User not found");
    }

    user.twoFactorEnabled = enable;
    await user.save();

    // Log 2FA toggle
    await logger.auth(
      enable ? "2FA_ENABLED" : "2FA_DISABLED",
      user._id,
      `2FA ${enable ? "enabled" : "disabled"}`,
      req
    );

    return user.toJSON();
  },

  /**
   * Logout user
   * @param {String} userId - User ID
   * @param {Object} req - Express request object
   */
  async logout(userId, req) {
    // Log logout
    await logger.auth("LOGOUT", userId, "User logged out", req);

    // Notify other services about logout
    await rabbitmq.sendMessage("auth-tokens", {
      type: "token.revoked",
      userId: userId.toString(),
      action: "logout",
      timestamp: new Date().toISOString(),
    });
  },
  /**
   * Forget password - Generate new password and send via email
   * @param {String} email - User email
   * @param {Object} req - Express request object
   */
  async forgetPassword(email, req) {
    try {
      console.log("🔍 Forget password request for:", email);

      // Find user by email
      const user = await User.findOne({ email }).populate("role");
      
      if (!user) {
        console.log("❌ User not found for email:", email);
        await logger.auth("FORGET_PASSWORD_FAILED", null, "Email not found", req, { email });
        return {
          success: true,
          message: "If your email is registered, you will receive a new password shortly."
        };
      }

      console.log("✅ User found:", user._id, user.email);

      if (!user.active) {
        console.log("❌ User account is inactive:", user._id);
        await logger.auth("FORGET_PASSWORD_FAILED", user._id, "Account is inactive", req);
        throw new Error("Account is inactive. Please contact support.");
      }

      // Generate new random password
      const newPassword = crypto.randomBytes(8).toString('hex');
      console.log("🔑 Generated new password:", newPassword);

      // ✅ FIX: Update password directly in database to bypass pre-save hook
      // This prevents double-hashing
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      console.log("🔒 Manually hashed password");

      // Update directly in database without triggering pre-save middleware
      await User.updateOne(
        { _id: user._id },
        { 
          $set: { 
            password: hashedPassword,
            resetPasswordToken: undefined,
            resetPasswordExpires: undefined
          }
        }
      );
      console.log("💾 Password updated directly in database");

      // Verify the password was saved correctly
      const updatedUser = await User.findById(user._id);
      const testMatch = await bcrypt.compare(newPassword, updatedUser.password);
      console.log("🧪 Password verification test:", testMatch);

      if (!testMatch) {
        console.error("❌ CRITICAL: Password verification failed after save!");
        throw new Error("Password update failed. Please try again.");
      }

      // Log password reset
      await logger.auth("FORGET_PASSWORD_SUCCESS", user._id, "New password generated and sent", req);

      // Send new password via email
      try {
        await emailUtil.sendTemplatedEmail(email, "newPassword", {
          name: `${user.firstname} ${user.lastname}`,
          email: user.email,
          newPassword: newPassword
        });
        console.log("📧 New password sent successfully to:", email);
      } catch (emailError) {
        console.error("❌ Failed to send new password email:", emailError);
        throw new Error("Failed to send new password. Please try again later.");
      }

      // Notify other services
      try {
        await rabbitmq.sendMessage("auth-events", {
          type: "password.reset",
          userId: user._id.toString(),
          email: user.email,
          timestamp: new Date().toISOString()
        });
      } catch (mqError) {
        console.error("⚠️ Failed to send password reset event:", mqError.message);
      }

      return {
        success: true,
        message: "A new password has been sent to your email address."
      };

    } catch (error) {
      console.error("❌ Forget password error:", error);
      throw error;
    }
  },
  async changePassword(userId, currentPassword, newPassword, req) {
    try {
      console.log("🔄 Change password request for user:", userId);

      if (!currentPassword || !newPassword) {
        throw new Error("Current password and new password are required");
      }

      if (newPassword.length < 6) {
        throw new Error("New password must be at least 6 characters long");
      }

      if (currentPassword === newPassword) {
        throw new Error("New password must be different from current password");
      }

      const user = await User.findById(userId).populate("role");
      
      if (!user || !user.active) {
        console.log("❌ User not found or inactive:", userId);
        await logger.auth("CHANGE_PASSWORD_FAILED", userId, "User not found or inactive", req);
        throw new Error("User account not found or inactive");
      }

      console.log("✅ User found:", user.email);

      const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
      console.log("🧪 Current password verification:", isCurrentPasswordValid);

      if (!isCurrentPasswordValid) {
        console.log("❌ Current password verification failed");
        await logger.auth("CHANGE_PASSWORD_FAILED", userId, "Invalid current password", req);
        throw new Error("Current password is incorrect");
      }

      const hashedNewPassword = await bcrypt.hash(newPassword, 10);
      console.log("🔒 New password hashed successfully");

      await User.updateOne(
        { _id: userId },
        { 
          $set: { 
            password: hashedNewPassword,
            resetPasswordToken: undefined,
            resetPasswordExpires: undefined,
            twoFactorCode: undefined,
            twoFactorExpires: undefined
          }
        }
      );
      console.log("💾 Password updated in database");

      const updatedUser = await User.findById(userId);
      const testNewPassword = await bcrypt.compare(newPassword, updatedUser.password);
      console.log("🧪 New password verification test:", testNewPassword);

      if (!testNewPassword) {
        console.error("❌ CRITICAL: New password verification failed!");
        throw new Error("Password update failed. Please try again.");
      }

      await logger.auth("PASSWORD_CHANGED", userId, "Password changed successfully", req);

      try {
        await emailUtil.sendTemplatedEmail(user.email, "passwordChanged", {
          name: `${user.firstname} ${user.lastname}`,
          email: user.email,
          timestamp: new Date().toLocaleString()
        });
        console.log("📧 Password change confirmation email sent");
      } catch (emailError) {
        console.error("⚠️ Failed to send confirmation email:", emailError.message);
      }

      try {
        await rabbitmq.sendMessage("auth-events", {
          type: "password.changed",
          userId: userId.toString(),
          email: user.email,
          timestamp: new Date().toISOString()
        });
      } catch (mqError) {
        console.error("⚠️ Failed to send password change event:", mqError.message);
      }

      return {
        success: true,
        message: "Password changed successfully. Please login again with your new password."
      };

    } catch (error) {
      console.error("❌ Change password error:", error);
      throw error;
    }
  },
};
