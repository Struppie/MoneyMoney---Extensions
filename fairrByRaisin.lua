--
-- MoneyMoney Web Banking extension
-- http://moneymoney-app.com/api/webbanking
--
--
-- The MIT License (MIT)
--
-- Copyright (c) Stefan Ditscheid
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
--
-- Get balance for sparen.fairr.de/cockpit
--
-- Changelog:
-- 17.04.2020   v1.01   Adapted webscraping to new website content (amounts did not load correctly)
-- 11.11.2020   v1.10   Adapted webscraping to new website via this URL: https://fairr.raisin-pension.de/cockpit/
--

WebBanking {
    version     = 1.10,
    country     = "de",
    url         = "https://fairr.raisin-pension.de",
    services    = {"fairr - Cockpit"},
    description = string.format(MM.localizeText("Get balance for %s"), "fairr. by raisin")
}

function SupportsBank (protocol, bankCode)
    return bankCode == "fairr - Cockpit" and protocol == ProtocolWebBanking
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
    connection = Connection()
    connection.language = "de-de"

    local response = HTML(connection:get(url .. "/login/"))
    response:xpath("//*[@id='email']"):attr("value", username)
    response:xpath("//*[@id='password']"):attr("value", password)
    local loginresponse = HTML(connection:request(response:xpath("//button[@type='submit']"):click()))

    if (loginresponse:xpath("//*[@class='error_msg']/p"):text() == "Ihre Anmeldung konnte nicht bestätigt werden.") then
        return LoginFailed
    end
end

function ListAccounts (knownAccounts)
    local accounts = {}
    local response = HTML(connection:get(url .. "/cockpit/meine-produkte/"))

    response:xpath("//div[@class='product-tile']"):each(function(index, element)
        text = element:xpath("div[1]/div[2]/a[@class='btn btn-lg btn-outline']"):attr("href")
        print("LA: " .. index .. " = " .. text)
        i1, i2 = string.find(text, "=")

        if i2 ~= nil then
            if index == 1 then
                -- fairrürup
                local account = {
                    name = "fairrürup",
                    owner = "",
                    accountNumber = string.sub(text, i2+1),
                    curreny = "EUR",
                    type = AccountTypePortfolio,
                    portfolio = true
                }
                table.insert(accounts, account)
            elseif index == 2 then
                -- fairriester
                local account = {
                    name = "fairriester",
                    owner = "",
                    accountNumber = string.sub(text, i2+1),
                    curreny = "EUR",
                    type = AccountTypePortfolio,
                    portfolio = true
                }
                table.insert(accounts, account)
            elseif index == 3 then
                -- fairrbav
                local account = {
                    name = "fairrbav",
                    owner = "",
                    accountNumber = string.sub(text, i2+1),
                    curreny = "EUR",
                    type = AccountTypePortfolio,
                    portfolio = true
                }
                table.insert(accounts, account)
            end
        end
    end)

    return accounts
end

function RefreshAccount (account, since)
    local transactions = {}
    local response = HTML(connection:get(url .. "/cockpit/produkt/portfolio/?vertragsnummer=" .. account.accountNumber))

    response:xpath("//div[@class='row light-row-body portfolio-row']"):each(function(index, element)

        local transaction = {
            name = element:xpath("div[2]/div[1]"):text(),
            securityNumber = element:xpath("div[2]/div[2]/div[2]"):text():gsub("WKN: ", ""),
            market = "fairr",
            currency = "EUR",
            amount = tonumber((element:xpath("div[3]/div[2]"):text():gsub("%.", ""):gsub(",", "."):gsub(" EUR", ""))),
        }

        print("index: " .. index)
        print("name: " .. transaction.name)
        print("securityName: " .. transaction.securityNumber)
        print("amount: " .. transaction.amount)

        table.insert(transactions, transaction)

    end)

    return {securities = transactions}
end

function EndSession ()
    connection:get(url .. "/logout/")

    print("Logout successful.")
end

-- SIGNATURE: MC0CFBFtBOH5FDZyiE7OCeBxbdkBIjqRAhUAiNIeetXLU7dWdfVwcAGDgx1pL+s=
