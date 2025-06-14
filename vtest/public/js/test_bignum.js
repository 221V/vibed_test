
// todo test without bigint lib -- just browser bigint

function randomInteger(min, max){
  let rand = min + Math.random() * (max + 1 - min);
  return Math.floor(rand);
}

function test_number(){
  for(var i = 0; i < 10; i++){
    //var rand_value = randomInteger(1, 9007199254740991); // Number.MAX_SAFE_INTEGER = 2^53 - 1
    //var rand_value = randomInteger(-9007199254740991, 0); // Number.MIN_SAFE_INTEGER = (-(2^53 - 1))
    //var rand_value = randomInteger(-2147483648, 0);
    //var rand_value = randomInteger(2147483648, 9007199254740991);
    var rand_value = randomInteger(-9007199254740991, -2147483649);
    console.log(rand_value);
    //ws.send(enc(tuple( atom('атом'), number(rand_value) )));
    //ws.send(enc(tuple( atom('client'), tuple( atom('атом'), number(rand_value) ) )));
    ws.send(enc(tuple( atom('client'), tuple( atom('test'), number(rand_value) ) )));
  }
}

function test_bignum(){
  for(var i = 0; i < 10; i++){
    var rand_value = bigInt.randBetween("-18446744073709551615", "18446744073709551615");
    console.log(rand_value.toString());
    ws.send(enc(tuple( atom('client'), tuple( atom('test'), bignum(rand_value) ) )));
  }
}


