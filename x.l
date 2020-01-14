%{
#include "defs.h"
#include "x.tab.h"
int process_token(const char *text, const char *TokenType, const char *TokenVal, const int TokenID);
%}

id [A-Za-z:_][A-Za-z:_0-9-]*

%x ST_COMMENT ST_PI ST_TAG


%%

 /* Usuwanie komentarzy */
<INITIAL>"<!--" { BEGIN(ST_COMMENT); }
<ST_COMMENT>.|\n ;
<ST_COMMENT>[^-]"-->" {BEGIN(INITIAL); }

<INITIAL>"<?"{id} {BEGIN(ST_PI); return process_token(yytext, "PI_TAG_BEG",yytext+2, PI_TAG_BEG);}
<ST_PI>"?>" {BEGIN(INITIAL); return process_token(yytext, "PI_TAG_END", "", PI_TAG_END);}
<ST_PI>.|\n ;




<INITIAL>"<"{id} {BEGIN(ST_TAG); return process_token(yytext, "STAG_BEG", yytext+1, STAG_BEG);}
<INITIAL>"</"{id} {BEGIN(ST_TAG); return process_token(yytext, "ETAG_BEG", yytext+2, ETAG_BEG);}
<ST_TAG>"/>" {BEGIN(INITIAL); return process_token(yytext, "ETAG_END", "",ETAG_END);}
<ST_TAG>">" {BEGIN(INITIAL); return process_token(yytext, "TAG_END", "",TAG_END);}
<ST_TAG>.|\n ;


"&lt" return process_token(yytext, "CHAR", "<", CHAR);
"&gt" return process_token(yytext, "CHAR", ">", CHAR);
"&amp" return process_token(yytext, "CHAR", "&", CHAR);
"&apos" return process_token(yytext, "CHAR", "'", CHAR);
"&quote" return process_token(yytext, "CHAR", "\"", CHAR);
^[ \t]* ;
\n return process_token(yytext, "CHAR", yytext, '\n');
[\r] ;
[ \t] return process_token(yytext, "S", yytext, S);
. return process_token(yytext, "CHAR", yytext, CHAR);

%% 

int yywrap() {
  if (YYSTATE == ST_COMMENT) printf("Brak zamkniecia komentarza\n");
  if (YYSTATE == ST_PI) printf("Brak zamkniecia instrukcji przetwarzania\n");
  if (YYSTATE == ST_TAG) printf("Brak zamkniecia znacznika\n");

  return 1; 
}

char *strnncpy(char *dst, const char *src, const int n)
{
  if (n > 0) {
    strncpy(dst, src, n);
  }
  dst[n] = '\0';
  return dst;
}

int process_token(const char *text, const char *TokenType,
		  const char *TokenVal, const int TokenID)
{
  //printf("%-20.20s%-15s %s\n", text, TokenType, TokenVal);
  strncpy(yylval.s, TokenVal, MAXSTRLEN); 
  return(TokenID);
}
