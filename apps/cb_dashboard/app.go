package main

import (
	"encoding/json"
	"fmt"
	"syscall/js"
)

// DashboardStats represents summary statistics for the dashboard
type DashboardStats struct {
	TotalCustomers int   `json:"total_customers"`
	TotalAccounts  int   `json:"total_accounts"`
	TotalBalance   int64 `json:"total_balance"`
	TodayTxns      int   `json:"today_txns"`
	PendingTxns    int   `json:"pending_txns"`
}

// ActivityItem represents a recent activity feed item
type ActivityItem struct {
	ID          string `json:"id"`
	Type        string `json:"type"`
	Description string `json:"description"`
	Timestamp   int64  `json:"timestamp"`
	Amount      int64  `json:"amount"`
	Currency    string `json:"currency"`
}

// App represents the dashboard application state
type App struct {
	CurrentView     string
	Parties         []Party
	Accounts        []Account
	Transactions    []Transaction
	LedgerEntries   []LedgerEntry
	SavingsProducts []SavingsProduct
	LoanProducts    []LoanProduct
	Loans           []Loan
	LoanRepayments  []LoanRepayment
	SelectedParty   *Party
	SelectedAccount *Account
	SelectedLoan    *Loan
	Error           string
	Success         string
	Loading         bool

	// Dashboard specific
	Stats           DashboardStats
	RecentActivity  []ActivityItem
	SearchQuery     string
	FilterAccountID string
	FilterStatus    string
}

// Party represents a customer/party
type Party struct {
	PartyID   string `json:"party_id"`
	FullName  string `json:"full_name"`
	Email     string `json:"email"`
	Status    string `json:"status"`
	CreatedAt int64  `json:"created_at"`
	UpdatedAt int64  `json:"updated_at"`
}

// Account represents a bank account
type Account struct {
	AccountID string `json:"account_id"`
	PartyID   string `json:"party_id"`
	Name      string `json:"name"`
	Currency  string `json:"currency"`
	Balance   int64  `json:"balance"`
	Status    string `json:"status"`
	CreatedAt int64  `json:"created_at"`
	UpdatedAt int64  `json:"updated_at"`
}

// Transaction represents a financial transaction
type Transaction struct {
	TxnID           string `json:"txn_id"`
	IdempotencyKey  string `json:"idempotency_key"`
	TxnType         string `json:"txn_type"`
	Status          string `json:"status"`
	Amount          int64  `json:"amount"`
	Currency        string `json:"currency"`
	SourceAccountID string `json:"source_account_id"`
	DestAccountID   string `json:"dest_account_id"`
	Description     string `json:"description"`
	CreatedAt       int64  `json:"created_at"`
	PostedAt        int64  `json:"posted_at"`
}

// LedgerEntry represents a ledger entry
type LedgerEntry struct {
	EntryID     string `json:"entry_id"`
	TxnID       string `json:"txn_id"`
	AccountID   string `json:"account_id"`
	EntryType   string `json:"entry_type"`
	Amount      int64  `json:"amount"`
	Currency    string `json:"currency"`
	Description string `json:"description"`
	PostedAt    int64  `json:"posted_at"`
}

// SavingsProduct represents a savings product definition
type SavingsProduct struct {
	ProductID         string `json:"product_id"`
	Name              string `json:"name"`
	Description       string `json:"description"`
	Currency          string `json:"currency"`
	InterestRateBps   int64  `json:"interest_rate_bps"`
	InterestType      string `json:"interest_type"`
	CompoundingPeriod string `json:"compounding_period"`
	MinimumBalance    int64  `json:"minimum_balance"`
	Status            string `json:"status"`
	CreatedAt         int64  `json:"created_at"`
	UpdatedAt         int64  `json:"updated_at"`
}

// LoanProduct represents a loan product definition
type LoanProduct struct {
	ProductID       string `json:"product_id"`
	Name            string `json:"name"`
	Description     string `json:"description"`
	Currency        string `json:"currency"`
	MinAmount       int64  `json:"min_amount"`
	MaxAmount       int64  `json:"max_amount"`
	MinTermMonths   int64  `json:"min_term_months"`
	MaxTermMonths   int64  `json:"max_term_months"`
	InterestRateBps int64  `json:"interest_rate_bps"`
	InterestType    string `json:"interest_type"`
	Status          string `json:"status"`
	CreatedAt       int64  `json:"created_at"`
	UpdatedAt       int64  `json:"updated_at"`
}

// Loan represents a loan account
type Loan struct {
	LoanID             string `json:"loan_id"`
	ProductID          string `json:"product_id"`
	PartyID            string `json:"party_id"`
	AccountID          string `json:"account_id"`
	Principal          int64  `json:"principal"`
	Currency           string `json:"currency"`
	InterestRateBps    int64  `json:"interest_rate_bps"`
	TermMonths         int64  `json:"term_months"`
	MonthlyPayment     int64  `json:"monthly_payment"`
	OutstandingBalance int64  `json:"outstanding_balance"`
	Status             string `json:"status"`
	DisbursedAt        int64  `json:"disbursed_at"`
	CreatedAt          int64  `json:"created_at"`
	UpdatedAt          int64  `json:"updated_at"`
}

// LoanRepayment represents a loan repayment record
type LoanRepayment struct {
	RepaymentID      string `json:"repayment_id"`
	LoanID           string `json:"loan_id"`
	Amount           int64  `json:"amount"`
	PrincipalPortion int64  `json:"principal_portion"`
	InterestPortion  int64  `json:"interest_portion"`
	Penalty          int64  `json:"penalty"`
	DueDate          int64  `json:"due_date"`
	PaidAt           int64  `json:"paid_at"`
	Status           string `json:"status"`
	CreatedAt        int64  `json:"created_at"`
}

// BalanceResponse represents a balance response
type BalanceResponse struct {
	AccountID        string `json:"account_id"`
	Currency         string `json:"currency"`
	Balance          int64  `json:"balance"`
	BalanceFormatted string `json:"balance_formatted"`
}

// NewApp creates a new App instance
func NewApp() *App {
	return &App{
		CurrentView:     "dashboard",
		Parties:         []Party{},
		Accounts:        []Account{},
		Transactions:    []Transaction{},
		LedgerEntries:   []LedgerEntry{},
		SavingsProducts: []SavingsProduct{},
		LoanProducts:    []LoanProduct{},
		Loans:           []Loan{},
		LoanRepayments:  []LoanRepayment{},
		RecentActivity:  []ActivityItem{},
		Stats:           DashboardStats{},
	}
}

// Navigate changes the current view
func (a *App) Navigate(this js.Value, args []js.Value) interface{} {
	if len(args) > 0 {
		a.CurrentView = args[0].String()
		a.Render()
	}
	return nil
}

// Render renders the current view to the DOM
func (a *App) Render() {
	doc := js.Global().Get("document")
	root := doc.Call("getElementById", "root")

	if root.IsNull() {
		fmt.Println("Root element not found")
		return
	}

	// Clear root
	root.Set("innerHTML", "")

	// Create main layout with sidebar
	layout := doc.Call("createElement", "div")
	layout.Set("className", "app-layout")

	// Render sidebar
	sidebar := a.renderSidebar()
	layout.Call("appendChild", sidebar)

	// Render main content area
	mainContent := doc.Call("createElement", "div")
	mainContent.Set("className", "main-content")

	// Header bar
	header := a.renderHeader()
	mainContent.Call("appendChild", header)

	// Content area
	content := doc.Call("createElement", "div")
	content.Set("className", "content-area")

	// Loading indicator
	if a.Loading {
		loadingDiv := doc.Call("createElement", "div")
		loadingDiv.Set("className", "loading-spinner")
		loadingDiv.Set("textContent", "Loading...")
		loadingDiv.Call("setAttribute", "data-testid", "loading")
		content.Call("appendChild", loadingDiv)
	} else {
		// Render error if any
		if a.Error != "" {
			errorDiv := doc.Call("createElement", "div")
			errorDiv.Set("className", "alert alert-error")
			errorDiv.Set("textContent", a.Error)
			errorDiv.Call("setAttribute", "data-testid", "error-banner")
			content.Call("appendChild", errorDiv)
		}

		// Render success message if any
		if a.Success != "" {
			successDiv := doc.Call("createElement", "div")
			successDiv.Set("className", "alert alert-success")
			successDiv.Set("textContent", a.Success)
			successDiv.Call("setAttribute", "data-testid", "success-banner")
			content.Call("appendChild", successDiv)
		}

		// Render current view
		switch a.CurrentView {
		case "dashboard":
			content.Call("appendChild", a.renderDashboardHome())
		case "customers":
			content.Call("appendChild", a.renderCustomersView())
		case "accounts":
			content.Call("appendChild", a.renderAccountsListView())
		case "account-detail":
			content.Call("appendChild", a.renderAccountDetailView())
		case "transactions":
			content.Call("appendChild", a.renderTransactionsListView())
		case "ledger":
			content.Call("appendChild", a.renderLedgerView())
		case "products":
			content.Call("appendChild", a.renderProductsView())
		case "loans":
			content.Call("appendChild", a.renderLoansView())
		case "settings":
			content.Call("appendChild", a.renderSettingsView())
		case "transfer":
			content.Call("appendChild", a.renderTransferView())
		case "deposit":
			content.Call("appendChild", a.renderDepositView())
		default:
			content.Call("appendChild", a.renderDashboardHome())
		}
	}

	mainContent.Call("appendChild", content)
	layout.Call("appendChild", mainContent)
	root.Call("appendChild", layout)
}

func (a *App) renderSidebar() js.Value {
	doc := js.Global().Get("document")
	sidebar := doc.Call("createElement", "aside")
	sidebar.Set("className", "sidebar")

	// Logo/Brand
	brand := doc.Call("createElement", "div")
	brand.Set("className", "sidebar-brand")
	brandText := doc.Call("createElement", "h1")
	brandText.Set("textContent", "IronLedger")
	brandText.Set("className", "brand-title")
	brand.Call("appendChild", brandText)
	brandSubtitle := doc.Call("createElement", "span")
	brandSubtitle.Set("textContent", "Core Banking")
	brandSubtitle.Set("className", "brand-subtitle")
	brand.Call("appendChild", brandSubtitle)
	sidebar.Call("appendChild", brand)

	// Navigation items
	navItems := []struct {
		id    string
		label string
		icon  string
	}{
		{"dashboard", "Dashboard", "dashboard"},
		{"customers", "Customers", "group"},
		{"accounts", "Accounts", "account_balance"},
		{"transactions", "Transactions", "swap_horiz"},
		{"ledger", "Ledger", "book"},
		{"products", "Products", "inventory_2"},
		{"loans", "Loans", "request_quote"},
		{"settings", "Settings", "settings"},
	}

	nav := doc.Call("createElement", "nav")
	nav.Set("className", "sidebar-nav")

	for _, item := range navItems {
		btn := doc.Call("createElement", "button")
		btn.Set("className", "nav-item")
		btn.Call("setAttribute", "data-testid", "nav-"+item.id)
		if a.CurrentView == item.id {
			btn.Get("classList").Call("add", "active")
		}

		icon := createMaterialIcon(doc, item.icon, "nav-icon")

		label := doc.Call("createElement", "span")
		label.Set("textContent", item.label)
		label.Set("className", "nav-label")

		btn.Call("appendChild", icon)
		btn.Call("appendChild", label)

		viewName := item.id
		btn.Call("addEventListener", "click", js.FuncOf(func(this js.Value, args []js.Value) interface{} {
			a.CurrentView = viewName
			a.Error = ""
			a.Success = ""
			if viewName == "dashboard" {
				a.FetchDashboardStats(js.Value{}, nil)
			} else if viewName == "customers" {
				a.ListParties(js.Value{}, nil)
			} else if viewName == "accounts" {
				a.ListParties(js.Value{}, nil)
				a.ListAllAccounts(js.Value{}, nil)
			} else if viewName == "transactions" {
				a.ListAllTransactions(js.Value{}, nil)
			} else if viewName == "products" {
				a.ListSavingsProducts(js.Value{}, nil)
				a.ListLoanProducts(js.Value{}, nil)
			} else if viewName == "loans" {
				a.ListParties(js.Value{}, nil)
				a.ListAllAccounts(js.Value{}, nil)
				a.ListLoanProducts(js.Value{}, nil)
				a.ListLoansForSelectedParty()
			}
			a.Render()
			return nil
		}))

		nav.Call("appendChild", btn)
	}

	sidebar.Call("appendChild", nav)

	// Quick Actions section
	actionsTitle := doc.Call("createElement", "div")
	actionsTitle.Set("className", "sidebar-section-title")
	actionsTitle.Set("textContent", "Quick Actions")
	sidebar.Call("appendChild", actionsTitle)

	quickActions := []struct {
		id    string
		label string
		color string
	}{
		{"transfer", "Transfer Funds", "primary"},
		{"deposit", "Deposit / Withdraw", "success"},
	}

	for _, action := range quickActions {
		btn := doc.Call("createElement", "button")
		btn.Set("className", "quick-action-btn btn btn-"+action.color)
		btn.Set("textContent", action.label)
		btn.Call("setAttribute", "data-testid", "quick-"+action.id)

		viewName := action.id
		btn.Call("addEventListener", "click", js.FuncOf(func(this js.Value, args []js.Value) interface{} {
			a.CurrentView = viewName
			a.Error = ""
			a.Success = ""
			a.Render()
			return nil
		}))

		sidebar.Call("appendChild", btn)
	}

	return sidebar
}

func (a *App) renderHeader() js.Value {
	doc := js.Global().Get("document")
	header := doc.Call("createElement", "header")
	header.Set("className", "main-header")

	// Page title
	title := doc.Call("createElement", "div")
	title.Set("className", "header-title")

	pageTitle := doc.Call("createElement", "h2")
	pageTitle.Set("textContent", a.getPageTitle())
	pageTitle.Set("className", "page-title")
	title.Call("appendChild", pageTitle)

	header.Call("appendChild", title)

	// Header actions
	headerActions := doc.Call("createElement", "div")
	headerActions.Set("className", "header-actions")

	// Refresh button
	refreshBtn := doc.Call("createElement", "button")
	refreshBtn.Set("className", "header-btn")
	refreshBtn.Call("setAttribute", "title", "Refresh")

	refreshIcon := createMaterialIcon(doc, "autorenew", "header-icon")
	refreshBtn.Call("appendChild", refreshIcon)

	refreshBtn.Call("addEventListener", "click", js.FuncOf(func(this js.Value, args []js.Value) interface{} {
		a.RefreshCurrentView()
		return nil
	}))

	headerActions.Call("appendChild", refreshBtn)

	header.Call("appendChild", headerActions)

	return header
}

func (a *App) getPageTitle() string {
	switch a.CurrentView {
	case "dashboard":
		return "Dashboard"
	case "customers":
		return "Customers"
	case "accounts":
		return "Accounts"
	case "account-detail":
		return "Account Details"
	case "transactions":
		return "Transactions"
	case "ledger":
		return "Ledger"
	case "products":
		return "Products"
	case "loans":
		return "Loans"
	case "settings":
		return "Settings"
	case "transfer":
		return "Transfer Funds"
	case "deposit":
		return "Deposit / Withdraw"
	default:
		return "Dashboard"
	}
}

func (a *App) RefreshCurrentView() {
	switch a.CurrentView {
	case "dashboard":
		a.FetchDashboardStats(js.Value{}, nil)
	case "customers":
		a.ListParties(js.Value{}, nil)
	case "accounts":
		a.ListParties(js.Value{}, nil)
		a.ListAllAccounts(js.Value{}, nil)
	case "transactions":
		a.ListAllTransactions(js.Value{}, nil)
	case "products":
		a.ListSavingsProducts(js.Value{}, nil)
		a.ListLoanProducts(js.Value{}, nil)
	case "loans":
		a.ListParties(js.Value{}, nil)
		a.ListAllAccounts(js.Value{}, nil)
		a.ListLoanProducts(js.Value{}, nil)
		a.ListLoansForSelectedParty()
	case "account-detail":
		if a.SelectedAccount != nil {
			a.GetAccountDetails(js.Value{}, []js.Value{js.ValueOf(a.SelectedAccount.AccountID)})
		}
	}
	a.Render()
}

func capitalize(s string) string {
	if len(s) == 0 {
		return s
	}
	runes := []rune(s)
	runes[0] = rune(s[0] - 32)
	return string(runes)
}

func createMaterialIcon(doc js.Value, name string, className string) js.Value {
	icon := doc.Call("createElement", "span")
	icon.Set("className", className+" material-symbols-outlined")
	icon.Set("textContent", name)
	icon.Call("setAttribute", "aria-hidden", "true")
	return icon
}

// fetch makes an HTTP request to the API
func (a *App) fetch(method, url string, body interface{}, result interface{}) error {
	// This will be implemented using syscall/js fetch
	return fmt.Errorf("fetch not implemented")
}

// FormatAmount formats an amount for display
func FormatAmount(amount int64, currency string) string {
	switch currency {
	case "JPY":
		return fmt.Sprintf("¥%d", amount)
	case "USD":
		return fmt.Sprintf("$%.2f", float64(amount)/100)
	case "EUR":
		return fmt.Sprintf("€%.2f", float64(amount)/100)
	case "GBP":
		return fmt.Sprintf("£%.2f", float64(amount)/100)
	case "CHF":
		return fmt.Sprintf("CHF %.2f", float64(amount)/100)
	default:
		return fmt.Sprintf("%d", amount)
	}
}

// ParseAmount parses a decimal string to minor units
func ParseAmount(amountStr string) (int64, error) {
	var dollars, cents int64
	_, err := fmt.Sscanf(amountStr, "%d.%d", &dollars, &cents)
	if err != nil {
		// Try without cents
		_, err = fmt.Sscanf(amountStr, "%d", &dollars)
		if err != nil {
			return 0, err
		}
		cents = 0
	}
	return dollars*100 + cents, nil
}

// ToJSObject converts a Go value to a JavaScript object
func ToJSObject(v interface{}) js.Value {
	jsonBytes, _ := json.Marshal(v)
	return js.Global().Get("JSON").Call("parse", string(jsonBytes))
}
