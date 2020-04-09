local DATABASE = {};

DATABASE.CONNECT = function()
    local CONNECTION_TICK = getTickCount();

    if not DATABASE.CONNECTION or DATABASE.CONNECTION == nil then
        DATABASE.CONNECTION = dbConnect("mysql", string.format("dbname=%s;host=%s;port=%d;charset=utf8;unix_socket=/var/run/mysqld/mysqld.sock", DATABASE_CONFIG.DATABASE or "mm_db", DATABASE_CONFIG.HOST or "localhost", DATABASE_CONFIG.PORT or 3306), DATABASE_CONFIG.USER_DATA.LOGIN or "root", DATABASE_CONFIG.USER_DATA.PASSWORD or "", "share=1;autoreconnect=1;");
        if DATABASE.CONNECTION ~= nil and DATABASE.CONNECTION then
            outputDebugString(string.format("Połączono z serwerem bazy danych (w %d ms).", getTickCount() - CONNECTION_TICK));
        else
            outputDebugString("Nie można połączyć się z serwerem bazy danych."); 
        end;
    end;
end;
addEventHandler("onResourceStart", resourceRoot, DATABASE.CONNECT);

DATABASE.QUERY = function(...)
    if not DATABASE.CONNECTION or DATABASE.CONNECTION == nil then return end;
    if not {...} then return end;

    local qh = dbQuery(DATABASE.CONNECTION, ...);
    if not qh then return nil end;

    local rows = dbPoll(qh, -1);
    return rows;
end;

DATABASE.SINGLE = function(...)
    if not DATABASE.CONNECTION or DATABASE.CONNECTION == nil then return end;
    if not {...} then return end;

    local query = dbQuery(DATABASE.CONNECTION, ...);
    if not query then return nil end;

    local rows = dbPoll(query, -1);
    if not rows then return nil end;

    return rows[1];
end;

DATABASE.ROWS = function(...)
    if not DATABASE.CONNECTION or DATABASE.CONNECTION == nil then return end;
    if not {...} then return end;

    local query = dbQuery(DATABASE.CONNECTION, ...);
    if not query then return nil end;

    local rows = dbPoll(query, -1);
    if not rows then return nil end;

    return rows;
end;

function query(...) return DATABASE.QUERY(...) end;
function single(...) return DATABASE.SINGLE(...) end;
function rows(...) return DATABASE.ROWS(...) end;