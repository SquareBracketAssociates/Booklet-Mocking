## BabyMock: A Visual Mock Library
assert: result equals: 'XII'.
publisher publish: testEvent.
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'PharoForTheEnterprise '
mock should receive: #message:; with: argument1 and: argument2.
	| creditCard cart |
	creditCard := context mock: 'credit card'.
	cart := ShoppingCart payment: creditCard.		
	
	creditCard shouldnt receive: #charge:.
	cart checkout.
	"empty implementation"
	priceCatalog := context mock: 'price catalog'.
	creditCard := context mock: 'credit card'.
	cart := ShoppingCart 
		payment: creditCard 
		catalog: priceCatalog.		
	priceCatalog can receive: #priceOf:; with: #sku1; answers: 80.
	creditCard should receive: #charge:; with: 80.
	
	cart addSKU: #sku1.
	cart checkout.
	sku := aString.
	creditCard charge: (priceCatalog priceOf: sku).
	sku ifNotNil:
		[creditCard charge: (priceCatalog priceOf: sku)]
	priceCatalog can receive: #priceOf:; with: #sku1; answers: 10.
	priceCatalog can receive: #priceOf:; with: #sku2; answers: 30.
	priceCatalog can receive: #priceOf:; with: #sku3; answers: 50.
	creditCard should receive: #charge:; with: 90.
	
	cart addSKU: #sku1.
	cart addSKU: #sku2.
	cart addSKU: #sku3.	
	cart checkout.
	super initialize.
	skus := OrderedCollection new.
	skus add: aString.
	skus ifNotEmpty: 
		[ creditCard charge: (skus sum: [ :each | priceCatalog priceOf: each ])]
	self prices: {#sku1 -> 10. #sku2 -> 30. #sku3 -> 50}.
	creditCard should receive: #charge:; with: 90.
	
	cart addSKU: #sku1.
	cart addSKU: #sku2.
	cart addSKU: #sku3.	
	cart checkout.
	associations do:
		[:each |
			priceCatalog 
				can receive: #priceOf:; 
				with: each key; 
				answers: each value].
	skus ifNotEmpty: 
		[creditCard charge: self orderPrice]
	^ skus sum: [:each | priceCatalog priceOf: each]
	self prices: {#sku1 -> 30. #sku2 -> 70.}.
	creditCard should receive: #charge:; with: 30.
	
	cart addSKU: #sku1.
	cart addSKU: #sku2.
	cart removeSKU: #sku2.	
	cart checkout.
	skus remove: aSymbol.
	self prices: {#sku1 -> 20. #sku2 -> 30}.
	discountCalculator can receive: #calculateDiscount:; with: 50; answers: 10.	
	creditCard should receive: #charge:; with: 40.
	
	cart addSKU: #sku1.
	cart addSKU: #sku2.	
	cart checkout.
	| orderPrice discountPrice |
	skus ifNotEmpty: 
		[orderPrice := self orderPrice.
		discountPrice := self discountPrice: orderPrice.
		creditCard charge: orderPrice - discountPrice]	
	^ discountCalculator calculateDiscount: orderPrice
	discountCalculator can receive: #calculateDiscount:; answers: 0.
	|purchase|
	self prices: {#sku1 -> 10. #sku2 -> 30}; noDiscount.
	purchase := context states: 'purchase' startsAs: #firstPurchase.
	
	creditCard should 
		receive: #charge:; with: 10; 
		when: purchase is: #firstPurchase; 
		then: purchase is: #secondPurchase.
	creditCard should 
		receive: #charge:; with: 30;	
		when: purchase is: #secondPurchase.
	
	cart addSKU: #sku1.
	cart checkout.	
	cart addSKU: #sku2.
	cart checkout.
	| orderPrice discountPrice |
	skus ifNotEmpty: 
		[orderPrice := self orderPrice.
		discountPrice := self discountPrice: orderPrice.
		skus removeAll.
		creditCard charge: orderPrice - discountPrice]	
	receive: #next;
	answers: 1;
	answers: 2;
	signals: NoMoreElement.
iterator next. "returns 2"
iterator next. "signals NoMoreElement"
	self prices: {#sku -> 25}; noDiscount.	
	creditCard should 
		receive: #charge:; with: 25;
		exactly: #twice;
		signals: PaymentError;
		answers: true.
	
	cart addSKU: #sku.
	self should: [cart checkout] raise: PaymentError.
	cart checkout.
	| orderPrice discountPrice |
	skus ifNotEmpty: 
		[orderPrice := self orderPrice.
		discountPrice := self discountPrice: orderPrice.		
		creditCard charge: orderPrice - discountPrice.
		skus removeAll]	        	
	| catalog |
	catalog := PriceCatalogDictionary withPrices {#sku1 -> 10}.
	self assert catalog priceOf: #sku1 equals: 10.
	| response |
	response := ZnClient new
		url: 'http://example.com/rest/sku/', sku;
		get;
		response.
	^ self parseResponse: repsonse.