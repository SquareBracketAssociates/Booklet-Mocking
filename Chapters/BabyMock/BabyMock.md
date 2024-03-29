## BabyMock: A Visual Mock LibraryBabyMock is a visual mock object library for Pharo Smalltalk, that supports test-driven development. A mock object is a replacement for a real object that helps you design and verify object interactions. BabyMock makes it easy to create mock objects as well as visualizes the object interactions. This visualization may help you to get a good mental picture of the objects relationships. In this chapter, we will describe how to use mock objects in conjunction with test-driven development.  ### Todo for the book- how to load it- add some pictures- check the difference with the wiki on [http://smalltalkhub.com/#!/\~zeroflag/BabyMock2](http://smalltalkhub.com/#!/~zeroflag/BabyMock2) because it looks complementary### About Test-Driven Development and Mock ObjectsTest-Driven Development is a software development technique in which programmers write tests before they write the code itself. In the tests they make assertions about the expected behavior of the object under test. There are two kinds of assertions, the ones where you assert that an object answered correctly in response to a query message and the ones where you assert that an object sent the correct message to an other object. A mock object library helps in the latter case by providing a framework for setting up those assertions.The assertion against a returned value is at the end of the test.```result := calculator add: 'V' to: 'VII'.
assert: result equals: 'XII'.```However, assertions about interactions are at the beginning. We'll call them expectations later on.```subscriber should receive: #eventReceived:; with: testEvent.
publisher publish: testEvent.```### TDD is not just about testingTest-Driven Development combined with mock objects supports good Object-Oriented design by emphasizing how the objects collaborates with each other rather than their internal implementation. Mock objects can help you discover object roles as well as design the communication protocols between the objects\[1\].We'll describe how to use mock objects and outside-in TDD in practice. We're going to use SUnit as our test framework \(we assume you're familiar with it\) and BabyMock as our mock object library. This will be more like a message \(or interaction\) oriented approach of TDD, so we chose the example codes accordingly. Depending on what problem you're trying to solve and what design strategy you're following, you might want to use simple assertions instead of mocks and expectations. But in an object oriented code there are plenty of places where objects _tell each other to do things_\[2\] therefore mocks will come in handy.### How does outside-in TDD work?We start with the action that triggers the behavior we want to implement and work our way from the outside towards the inside of the system. We work on one object at a time, and substitute its collaborator objects with mocks. Thus the interface of the collaborators are driven by the need of the object under test. We setup expectations on the mocks, which allows us to finish the implementation and testing of the object under test without the existence of concrete collaborators. After we finished an object, we can move on towards one of its collaborator and repeat the same process. ### Getting startedThe recommended way to use BabyMock is to extend your test from `BabyMockTestCase`, which is a subclass of  `TestCase`. After that you can run your test just like any other SUnit based unit test.```BabyMockTestCase subclass: #TestName
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'PharoForTheEnterprise '```### Creating mocks	Mocks can be created by sending a `mock:` message to the `context` with an arbitrary name string. The `context` is an instance variable in `BabyMockTestCase`, and it represents the neighbours of the object under test\[3\].```mock := context mock: 'name of the mock'.```After this you can define expectations on the mock like this.```"We expect the message: to be received once with two arguments"
mock should receive: #message:; with: argument1 and: argument2.```Now In the following sections, we will develop a complete sample application written with TDD.### A simple shopping cartLet's design a simple shopping cart that will calculate the price of the products and charge the customer's credit card. The total charge is calculated by subtracting the discount price from the total order amount. During this process we are going to discover several roles that mock objects will play.### Writing our first testAfter an incoming checkout message, the shopping cart will send a `charge:` message to a credit card object if it is not empty. This outgoing message and its argument is what we need to test in order to verify the behaviour of our shopping cart.Let's start with the simplest test when the shopping cart is empty. In this case no `charge:` message should be sent.```ShoppingCartTest >> testNoChargeWhenCartIsEmpty
	| creditCard cart |
	creditCard := context mock: 'credit card'.
	cart := ShoppingCart payment: creditCard.		
	
	creditCard shouldnt receive: #charge:.
	cart checkout.```The `creditCard` is a dependency for the shopping cart, so we pass it through a constructor method. Then we setup an expectation that `creditCard` won't receive a `#charge:` message with any argument. BabyMock signals error when it receives a message that was not defined by any expectation. Therefore the `shouldnt` is not necessary, but it makes the test more explicit and so easier to understand. Finally we trigger the behavior we want to test by sending a `checkout` message to the shopping cart.A ShoppingCart with an empty checkout method passes the test.```ShoppingCart >> checkout
	"empty implementation"```Usually we want to start with a failing test because we want to be sure that the test is capable of failing, then we can write just enough production code pass the test. This is an exceptional case, so we'll keep an eye on this test and come back to this later.### One product, no discountNow let's add one product id \(we'll call it SKU which is an abbreviation of stock keeping unit\) to the shopping cart and check the price being sent to the credit card. But to do so we need to know the price of the product. It would be helpful if there were an object that could find out the price of an item by its SKU. We can bring this object to existence with the help of the mock library. Let's create a mocked `priceCatalog` and move the initialization of the shopping cart in the `setUp` method.```ShoppingCartTest > >setUp
	priceCatalog := context mock: 'price catalog'.
	creditCard := context mock: 'credit card'.
	cart := ShoppingCart 
		payment: creditCard 
		catalog: priceCatalog.		```We converted the `cart` and `creditCard` temporary variables to instance variables because we are using them in both tests.Now we can setup and use the `priceCatalog` without worrying about its internal structure of an actual catalog.```ShoppingCartTest >> testChargingCardAfterBuyingOneProduct
	priceCatalog can receive: #priceOf:; with: #sku1; answers: 80.
	creditCard should receive: #charge:; with: 80.
	
	cart addSKU: #sku1.
	cart checkout.```This test will fail if:- the `charge:` is not sent to the `creditCard` during the test.- the `charge:` is sent more than once.- the argument of the `charge:` is different than 80.- an unexpected message is sent to the `creditCard` or to the `priceCatalog`.This test gives us our first failure:_credit card received <charge: 80> 0 time\(s\), but was expected exactly once_BabyMock complains about the missing `charge:` message, but it doesn't say anything about the `priceOf:`. BabyMock allows one to specify whether a message must be received or simply can be received. The first one uses `should` while the second uses the message `can`. Without this distinction the test would be less readable and more brittle. Let's imagine we're introducing a price caching mechanism in the shopping cart. So after we asked the price of a product we store it and next time we won't ask it again. This likely would cause test failures if we'd use exact expectations \(`should`\), even if the shopping cart would work correctly. Charging the credit card twice would be a serious mistake, but querying the product price twice is an implementation detail.Here is a simple rule to follow: allow \(with `can`\) queries that return values and expect \(with `should`\) commands that make objects to do some side effect. Of course, this is an oversimplified rule that does not hold all the time, but in can be useful in many cases.The following implementation passes the test.```ShoppingCart >> addSKU: aString
	sku := aString.``````ShoppingCart >> checkout
	creditCard charge: (priceCatalog priceOf: sku).```		This implementation isn't complete but it is just enough to pass the second test. We don't want to do more than it necessary to pass the test. This practice ensures high code coverage and helps keeping the implementation simple.Now our first test is finally broken because we charge the credit card \(with nil\) even if the cart is empty. This can be easily fixed by a nil check.```ShoppingCart >> checkout	
	sku ifNotNil:
		[creditCard charge: (priceCatalog priceOf: sku)]```### Many products, no discountThe shopping cart that can hold only one product isn't particularly useful. The next test will force us to generalize our implementation.```ShoppingCartTest >> testChargingCardAfterBuyingManyProducts
	priceCatalog can receive: #priceOf:; with: #sku1; answers: 10.
	priceCatalog can receive: #priceOf:; with: #sku2; answers: 30.
	priceCatalog can receive: #priceOf:; with: #sku3; answers: 50.
	creditCard should receive: #charge:; with: 90.
	
	cart addSKU: #sku1.
	cart addSKU: #sku2.
	cart addSKU: #sku3.	
	cart checkout.```This generates a failure message: _'credit card received message: <charge:> with different arguments: #\(50\)_'. The shopping cart keeps the last SKU only that's why it reports the wrong price. First we rename the `sku` instance variable to `skus` and intialize it to an empty `OrderedCollection`.```ShoppingCart >> initialize 
	super initialize.
	skus := OrderedCollection new.```Then we replace the assignment to an `add:` message in the `addSKU:` method.```ShoppingCart >> addSKU: aString
	skus add: aString.```Finally we change the nil check to an empty check and add the `orderPrice` calculation.```ShoppingCart >> checkout	
	skus ifNotEmpty: 
		[ creditCard charge: (skus sum: [ :each | priceCatalog priceOf: each ])]```Refactoring is part of TDD. We should check after each test if there is anything we can do to make the test and the code better. The setup of the `priceCatalog` adds a lot of noise to the last test. Let's extract it to a private method.```ShoppingCartTest >> testChargingCardAfterBuyingManyProducts
	self prices: {#sku1 -> 10. #sku2 -> 30. #sku3 -> 50}.
	creditCard should receive: #charge:; with: 90.
	
	cart addSKU: #sku1.
	cart addSKU: #sku2.
	cart addSKU: #sku3.	
	cart checkout.``````ShoppingCartTest >> prices: associations
	associations do:
		[:each |
			priceCatalog 
				can receive: #priceOf:; 
				with: each key; 
				answers: each value].```Then extract the `orderPrice` calculation into a new method:```ShoppingCart >> checkout
	skus ifNotEmpty: 
		[creditCard charge: self orderPrice]``````ShoppingCart >> orderPrice
	^ skus sum: [:each | priceCatalog priceOf: each]```### Removing a productThe shopping cart should provide methods for removing a product. We don't want to test the internal state of the shopping cart, because it would make our tests brittle. We assume that the interface of the shopping cart is more stable than its implementation, so we want to couple our tests to the interface of the object under test. We can verify the behaviour by checking that a product removal is reflected in the price.```ShoppingCartTest >> testProductRemovalReflectedInPrice
	self prices: {#sku1 -> 30. #sku2 -> 70.}.
	creditCard should receive: #charge:; with: 30.
	
	cart addSKU: #sku1.
	cart addSKU: #sku2.
	cart removeSKU: #sku2.	
	cart checkout.```Making the test pass is fairly simple.```ShoppingCart >> removeSKU: aSymbol 
	skus remove: aSymbol.```	### Products with discount priceWe know that there are rules for calculating the discount price. Those rules take the total order amount into account. Luckily we don't need to worry about what exactly the rules are. Let's introduce a new mock that will play the role of the `DiscountCalculator`.```ShoppingCartTest >> testChargingCardWithDiscount
	self prices: {#sku1 -> 20. #sku2 -> 30}.
	discountCalculator can receive: #calculateDiscount:; with: 50; answers: 10.	
	creditCard should receive: #charge:; with: 40.
	
	cart addSKU: #sku1.
	cart addSKU: #sku2.	
	cart checkout.```BabyMock complains that the `creditCard` was charged with an incorrect price \(50 instead of 40\). We need to subtract the `discountPrice` from the `orderPrice` to make the test pass.	```ShoppingCart >> checkout
	| orderPrice discountPrice |
	skus ifNotEmpty: 
		[orderPrice := self orderPrice.
		discountPrice := self discountPrice: orderPrice.
		creditCard charge: orderPrice - discountPrice]	```	```ShoppingCart >> discountPrice: orderPrice
	^ discountCalculator calculateDiscount: orderPrice```		Now the last test passed but some of the other tests are failing because we didn't expect the interaction with the `discountCalculator` there. Let's fix these tests by adding a `self noDiscount` to the them.		```ShoppingCartTest>>noDiscount
	discountCalculator can receive: #calculateDiscount:; answers: 0.```### Reusing the cart for different salesWe want the shopping cart to unload itself after the checkout so we'll able to reuse the same instance over and over. We'll simulate two separated purchase in the next test to verify this behaviour. This will trigger two `charge` messages. We'll check if the correct price is sent when the shopping cart is in the correct state \(`firstPurchase` or `secondPurchase`\).BabyMock provides a mechanism to define a state-machine which makes testing scenarios like this easier.```state := context states: 'state name' startsAs: #state1.```The first argument is the name of the states and the second is the initial state. You can check that an interaction happened in the expected state as follows.```mock should receive: #msg; when: state is: #state1.```This will change the state of state-machine to the `#state2` state when the interaction occurs.```mock should receive: #msg; then: state is: #state2.```Here is our new test that uses the state-machine.```ShoppingCartTest>>testUnloadsItselfAfterCheckout
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
	cart checkout.```Now, this is equivalent of a simple ordering test \(`charge: 10` must come before `charge: 30`\). But states are more powerful because you can loosen the ordering constraints. This makes possible to express scenarios like one event should happen first and others must follow it in any order.The test generates a failure message: _'credit card received message: <charge:> with different arguments: #\(40\)_'. But cleaning the `skus` collection in the `checkout` fixes the test.```ShoppingCart>>checkout
	| orderPrice discountPrice |
	skus ifNotEmpty: 
		[orderPrice := self orderPrice.
		discountPrice := self discountPrice: orderPrice.
		skus removeAll.
		creditCard charge: orderPrice - discountPrice]	```### Testing errors during checkoutWe expect the `creditCard` to report `PaymentError` when the payment was unsuccessful. When this happens, the shopping cart should not forget the content because we may want to retry the checkout later. #### Consecutive messagesSometimes we need to setup the mock to return different values \(or to signal different exceptions\) for the same message.```iterator can
	receive: #next;
	answers: 1;
	answers: 2;
	signals: NoMoreElement.```The first message sent to the iterator returns 1, while the second returns 2. On the third time it will signal `NoMoreElement`.```iterator next. "returns 1"
iterator next. "returns 2"
iterator next. "signals NoMoreElement"```#### Successful payment after failureIn the next test case we'll send two `checkout` message to the shopping cart, whereof the first will fail. The `creditCard` will signal `PaymentError` then answer `true` consecutively. ```ShoppingCartTest>>testFirstPaymentFailedSecondSucceed
	self prices: {#sku -> 25}; noDiscount.	
	creditCard should 
		receive: #charge:; with: 25;
		exactly: #twice;
		signals: PaymentError;
		answers: true.
	
	cart addSKU: #sku.
	self should: [cart checkout] raise: PaymentError.
	cart checkout.```The failure report is:_credit card received <charge: 25> 1 time\(s\), but was expected exactly 2 times_The test failed because we clean the `skus` collection before charging the credit card. So after the first checkout the shopping cart is empty, and the second time it won't charge the credit card.Let's move the `skus removeAll` at the end, to make the test pass.```ShoppingCart>>checkout
	| orderPrice discountPrice |
	skus ifNotEmpty: 
		[orderPrice := self orderPrice.
		discountPrice := self discountPrice: orderPrice.		
		creditCard charge: orderPrice - discountPrice.
		skus removeAll]	        	```### What's nextWe finished the shopping cart, so what's next? We can continue with either of its dependencies: `CreditCard`, `PriceCatalog`, `DiscountCalculator`.For example we may want to use a simple in-memory object for the `priceCatalog` and implement its internals using a `Dictionary`. In this case a simple assertion based test would cover its behaviour.```PriceCatalogDictionaryTest >> testKnowsThePriceOfAproduct
	| catalog |
	catalog := PriceCatalogDictionary withPrices {#sku1 -> 10}.
	self assert catalog priceOf: #sku1 equals: 10.```Another implementation might be an HTTP based remote price catalog which would use a REST web service to find out the price.```RemoteHttpPriceCatalog >> priceOf: sku
	| response |
	response := ZnClient new
		url: 'http://example.com/rest/sku/', sku;
		get;
		response.
	^ self parseResponse: repsonse.```We could mock the http client to test the `RemoteHttpPriceCatalog` but it would result duplications and wouldn't improve our confidence in the code. Mocking a third-party code often causes brittle test and doesn't tell us too much about code itself \(its design and correctness\). So we recommended wrapping the third-party API with an adapter \(See Alistair Cockburn Ports And Adapters Architecture\) that will provide a high level of abstraction. Think about the adapter like a translator that translates messages between two different domains \(`priceOf:` to http `get`\). But here the `RemoteHttpPriceCatalog` is already an adapter, introducing a new one would just delay the problem. We free to mock the adapter just as we did in the shopping cart tests, but we still need to test the `RemoteHttpPriceCatalog` somehow. We recommend testing the adapter itself with integration tests. In the contrast with unit tests \(what we did before\), integration tests don't test object in isolation. Writing a test like this would require firing up a local http server that could provide canned responses in an appropriate format. We'll leave those as an exercise for the reader.### ConclusionBabyMock is nice mock library.### References- \[1\]  Freeman, S., Mackinnon, T., Pryce, N., Walnes, J., [Mock Roles, Not Objects. OOPSLA 2004.](http://jmock.org/oopsla2004.pdf)- \[2\] [Tell don't ask is](http://c2.com/cgi/wiki?TellDontAsk) an object-oriented design principle.- \[3\] The context comes from [JMock](http://jmock.org/) which is a mock object library written in Java.- \[4\] Freeman, S. and Pryce, N. Growing Object-Oriented Software, Guided by Tests.