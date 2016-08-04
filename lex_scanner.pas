{Поиск многосимвольных идентификаторов, чисел,             }
{односимвольных и двухсимвольных операций во входном потоке}
program lex_scanner(input, oufput);

const txmax = 100; {длина таблицы имен}
      nmax = 14;   {максимальное количество цифр в числах}
      al = 255;     {максимальная длина имен}

type
t_object = (nul,num,ident,oper);

t_sym=record 
    kind:t_object; {тип идентификатора}
    tag:integer;   {вспомогательный элемент число-метка (зарезервировано)}
    i_name:integer;  {числовое имя-код идентификатора для быстрой обработки}
    s_name:string;   {строковое имя идентификатора}
end;
     
var ch,ch2: char; {последний прочитанный входной символ и следующий за ним}
    start_of_file, end_of_file:boolean;
    id: t_sym; {последний прочитанный идентификатор}
    id_table: array [0..txmax] of t_sym; {сводная таблица идентификаторов}
    tx: integer; {число идентификаторов в таблице}

{запись нового объекта (идентификатора), в таблицу}
procedure enter(new_id:t_sym);
begin
    tx:=tx+1;
    id_table[tx]:=new_id;
end {enter};

{поиск имени id в таблице объектов-идентификаторов}
function find_by_sname(id:string): integer;
var i,res: integer;
begin
  res:=0;
  for i:=1 to tx do
    if id_table[i].s_name=id then res:=i;
  find_by_sname:=res;
end {find_by_sname};

function find_by_iname(id:integer): integer;
var i,res: integer;
begin
  res:=0;
  for i:=1 to tx do
    if id_table[i].i_name=id then res:=i;
  find_by_iname:=res;
end {find_by_iname};

{прочитать из потока ввода два символа и поместить их в ch, ch2}
procedure getch;
begin
  if end_of_file then begin write('UNEXPECTED END OF FILE'); halt(-1); end;
  if eof(input) then end_of_file:=true;
  if start_of_file then begin ch:=' '; ch2:=' '; end;
  if end_of_file then begin ch:=ch2; ch2:=' '; end;

  if not(end_of_file) and not(start_of_file) then
  begin ch:=ch2; read(ch2); end;

  if not(end_of_file) and start_of_file then
  begin
     read(ch); start_of_file:=false;
     if not(eof(input)) then read(ch2) else ch2:=' ';
  end;
end {getch};
  
{найти во входном потоке терминальный символ}
procedure getsym;
begin {getsym}
  {пропускаем возможные пробелы и концы строк}
  while (ch=' ')or(ch=chr(10))or(ch=chr(13)) do getch;
  
  id.s_name:='';
  id.kind:=nul;
  
  {если ch - буква, или знак подчеркивния, то это - начало имени}
  if ch in ['A'..'Z','_'] then
  begin
    id.kind:=ident;
    {читаем посимвольно имя id[], состоящее из букв A-Z, цифр, подчеркивания}
    repeat
      id.s_name:=id.s_name+ch;
      getch;
    until not(ch in ['A'..'Z','0'..'9','_']);
  end
    else
  if ch in ['0'..'9'] then {если ch - цифра, то это - начало числа}
  begin
    id.kind:=num;
    repeat
      id.s_name:=id.s_name+ch;
      getch;
    until not(ch in ['0'..'9']);
  end
    else
  begin {односимвольный и некоторые двусимвольные идентификаторы}
    id.kind:=oper;
    if ch=',' then id.s_name:='comma';
    if ch=';' then id.s_name:='semicolon';
    if ch='!' then id.s_name:='exclamation';
    if ch='%' then id.s_name:='percent';
    if ch='?' then id.s_name:='question';
    if ch='#' then id.s_name:='grid';
    if ch='$' then id.s_name:='dollar';
    if ch='@' then id.s_name:='at_symbol';
    if ch='&' then id.s_name:='and_symbol';
    if ch='^' then id.s_name:='xor_symbol';
    if ch='/' then id.s_name:='slash';
    if ch='\' then id.s_name:='reverse_slash';
    if ch='|' then id.s_name:='or_symbol';
    if ch='=' then id.s_name:='equal';
    if ch='<' then id.s_name:='less';
    if ch='>' then id.s_name:='greater';
    if ch='(' then id.s_name:='left_paren';
    if ch=')' then id.s_name:='right_paren';
    if ch='{' then id.s_name:='figure_left_paren';
    if ch='}' then id.s_name:='figure_right_paren';
    if ch='[' then id.s_name:='square_left_paren';
    if ch=']' then id.s_name:='square_right_paren';
    if ch='+' then id.s_name:='plus';
    if ch='-' then id.s_name:='minus';
    if ch='*' then id.s_name:='times';
    if ch='.' then id.s_name:='period';
    if ch='''' then id.s_name:='quote';
    if ch='"' then id.s_name:='double_quote';
    if ch='`' then id.s_name:='alt_quote';
    if ch=':' then id.s_name:='colon';
    if ch='~' then id.s_name:='tilda';
    
    {разбор случаев двусимвольных спецкомбинаций}
    if (ch='-')and(ch2='>') then begin id.s_name:='arrow_to'; getch; end;
    if (ch='<')and(ch2='-') then begin id.s_name:='arrow_from'; getch; end;
    if (ch='<')and(ch2='>') then begin id.s_name:='not_equal'; getch; end;
    if (ch='!')and(ch2='=') then begin id.s_name:='not_equal'; getch; end;
    if (ch='=')and(ch2='=') then begin id.s_name:='double_equal'; getch; end;
    if (ch=':')and(ch2='=') then begin id.s_name:='becomes'; getch; end;
    if (ch='<')and(ch2='=') then begin id.s_name:='less_equal'; getch; end;
    if (ch='>')and(ch2='=') then begin id.s_name:='greater_equal'; getch; end;
    if (ch='(')and(ch2='*') then begin id.s_name:='left_paren_star'; getch; end;
    if (ch='*')and(ch2=')') then begin id.s_name:='right_paren_star'; getch; end;
    if (ch='+')and(ch2='+') then begin id.s_name:='double_plus'; getch; end;
    if (ch='-')and(ch2='-') then begin id.s_name:='double_minus'; getch; end;
    if (ch='*')and(ch2='*') then begin id.s_name:='double_times'; getch; end;
    if (ch='.')and(ch2='.') then begin id.s_name:='double_period'; getch; end;
    if (ch=':')and(ch2=':') then begin id.s_name:='double_colon'; getch; end;
    if (ch='/')and(ch2='/') then begin id.s_name:='double_slash'; getch; end;
    if (ch='|')and(ch2='|') then begin id.s_name:='double_or'; getch; end;
    if (ch='&')and(ch2='&') then begin id.s_name:='double_and'; getch; end;
    if (ch='^')and(ch2='^') then begin id.s_name:='double_xor'; getch; end;

    getch;
  end;
end {getsym};

begin {основная программа}
start_of_file:=true; end_of_file:=false; tx:=0; 

getch;
repeat
    getsym; 
    writeln('symbol=',id.s_name,', kind=',id.kind);
until id.s_name='period';

end.
