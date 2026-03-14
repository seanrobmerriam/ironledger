package main

import (
	"fmt"
	"syscall/js"
)

func main() {
	fmt.Println("IronLedger Dashboard starting...")

	// Initialize the app
	app := NewApp()

	// Set up global functions for JavaScript to call
	js.Global().Set("ironledger", js.ValueOf(map[string]interface{}{
		"navigate":            js.FuncOf(app.Navigate),
		"createParty":         js.FuncOf(app.CreateParty),
		"listParties":         js.FuncOf(app.ListParties),
		"suspendParty":        js.FuncOf(app.SuspendParty),
		"closeParty":          js.FuncOf(app.CloseParty),
		"createAccount":       js.FuncOf(app.CreateAccount),
		"listAccounts":        js.FuncOf(app.ListAccounts),
		"listAllAccounts":     js.FuncOf(app.ListAllAccounts),
		"freezeAccount":       js.FuncOf(app.FreezeAccount),
		"unfreezeAccount":     js.FuncOf(app.UnfreezeAccount),
		"closeAccount":        js.FuncOf(app.CloseAccount),
		"getBalance":          js.FuncOf(app.GetBalance),
		"getAccountDetails":   js.FuncOf(app.GetAccountDetails),
		"transfer":            js.FuncOf(app.Transfer),
		"deposit":             js.FuncOf(app.Deposit),
		"withdraw":            js.FuncOf(app.Withdraw),
		"getTransaction":      js.FuncOf(app.GetTransaction),
		"listTransactions":    js.FuncOf(app.ListTransactions),
		"listAllTransactions": js.FuncOf(app.ListAllTransactions),
		"reverseTransaction":  js.FuncOf(app.ReverseTransaction),
		"getLedgerEntries":    js.FuncOf(app.GetLedgerEntries),
		"fetchDashboardStats": js.FuncOf(app.FetchDashboardStats),
	}))

	// Fetch initial dashboard stats
	app.FetchDashboardStats(js.Value{}, nil)

	// Keep the program running
	select {}
}
