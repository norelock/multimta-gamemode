local database = exports["mm_db"];
local settings = exports["mm_settings"];

local PASSWORD_MANAGEMENT = {};

PASSWORD_MANAGEMENT.SALT = function(login, timestamp)
    if (type(login) == "string" and login and login:len() > 0) then
        if (type(timestamp) == "number" and timestamp) then
            return sha256(login .. ";" .. timestamp);
        end;
    end;
end;

PASSWORD_MANAGEMENT.GENERATE = function(salt, password)
    if (salt) then
        if (type(password) == "string" and password and password:len() > 0) then
            return teaEncode(base64Encode(string.format("%s;mm;%s", salt, password)), salt);
        end;
    end;
end;

local ACCOUNTS = {};

ACCOUNTS.LOGIN = function(player, login, password)
    local DB_PREFIX = settings:getSettingValue("DATABASE_PREFIX") or "multimta_";

    if not player or getElementType(player) ~= "player" then
        return;
    end;

    if (type(login) == "string" and login and login:len() > 0) then
        if (type(password) == "string" and password and password:len() > 0) then
            local account = database:single(string.format("SELECT * FROM %saccounts WHERE login=? LIMIT 1;", DB_PREFIX), login);

            if not account then
                return "ACCOUNT_NO_EXISTS";
            end;

            if getPlayerSerial(player) ~= account.serial then
                return "ACCOUNT_INVALID_OWNER";
            end;

            local salt = PASSWORD_MANAGEMENT.SALT(login, account.registered);
            local hash = PASSWORD_MANAGEMENT.GENERATE(salt, password);

            if hash == account.password then
                return "ACCOUNT_LOGGED_IN";
            else
                return "INVALID_PASSWORD";
            end;
        end;
    end;

    return nil;
end;

ACCOUNTS.REGISTER = function(player, login, password, email)
    local DB_PREFIX = settings:getSettingValue("DATABASE_PREFIX") or "multimta_";
    local ACCOUNTS_LIMIT = settings:getSettingValue("ACCOUNTS_LIMIT") or 1;

    if (type(login) == "string" and login and login:len() > 0) then
        if (type(password) == "string" and password and password:len() > 0) then
            if (type(email) == "string" and email and email:len() > 0) then
                local count = 0;

                local accounts = database:rows(string.format("SELECT 1 FROM %saccounts WHERE serial=?", DB_PREFIX), getPlayerSerial(player));
                for _, _ in ipairs(accounts) do count = count + 1; end;
                if count >= ACCOUNTS_LIMIT then return "ACCOUNTS_LIMIT"; end;

                local account = database:single(string.format("SELECT 1 FROM %saccounts WHERE login=? LIMIT 1;", DB_PREFIX), login);
                if account then
                    return "ACCOUNT_ALREADY_EXISTS";
                end;

                local timestamp = getRealTime().timestamp;

                local pass_salt = PASSWORD_MANAGEMENT.SALT(login, timestamp);
                local pass_hash = PASSWORD_MANAGEMENT.GENERATE(pass_salt, password);

                if database:query(string.format("INSERT INTO %saccounts SET login=?, password=?, email=?, serial=?, registered=?", DB_PREFIX), login, pass_hash, email, getPlayerSerial(player), timestamp) then
                    return "ACCOUNT_SUCCESSFULLY_REGISTERED";
                else
                    return "REGISTER_ERROR"; 
                end;
            end;
        end;
    end;

    return nil;
end;

function registerAccount(...) return ACCOUNTS.REGISTER(...) end; 
function logIntoAccount(...) return ACCOUNTS.LOGIN(...) end;