    unsigned func1(unsigned x) {
      return x + 1;
    }
    unsigned func2(unsigned x) {
      return x + 2;
    }
    unsigned func3(unsigned x) {
      return x + 3;
    }
    unsigned func4(unsigned x) {
      return x + 4;
    }
    unsigned func5(unsigned x) {
      return x + 5;
    }
    unsigned func6(unsigned x) {
      return x + 6;
    }
    unsigned func7(unsigned x) {
      return x + 7;
    }
    unsigned func8(unsigned x) {
      return x + 8;
    }
    unsigned func9(unsigned x) {
      return x + 9;
    }
    unsigned func10(unsigned x) {
      return x + 10;
    }
     unsigned use_all(unsigned x) {
       unsigned sum = x;
           sum = func1(sum);
    sum = func2(sum);
    sum = func3(sum);
    sum = func4(sum);
    sum = func5(sum);
    sum = func6(sum);
    sum = func7(sum);
    sum = func8(sum);
    sum = func9(sum);
    sum = func10(sum);
       return sum;
     }

     unsigned expected_output(unsigned x) {
         unsigned nf =  10;
         return (nf*(nf+1) / 2) + x;
     }
