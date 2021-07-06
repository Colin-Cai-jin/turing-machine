#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef STEP_ALLOC
#define STEP_ALLOC	1000000
#endif

#define STAT_INIT	0
#define STAT_ACCEPT	1
#define STAT_REJECT	2
#define BLANK		0
int max_stat;
int max_letter;
int current_stat;
int tape_len;
unsigned char* tape;
int tape_pos;
typedef struct {
	int next_stat;
	unsigned char next_letter;
	char dir;
} rule_t;
rule_t **rules;

int read_rules(const char *turing_machine_desc)
{
	FILE *f;
	int i;
	int stat, letter, next_stat, next_letter, dir;
	char s_letter[10], s_next_stat[10], s_next_letter[10];
	char s_dir[10];
	char buf[100];
	char *p;

	f = fopen(turing_machine_desc, "rb");
	while(fgets(buf, 99, f) != NULL) {
		p = strchr(buf, '#');
		if(p != NULL)
			*p = '\0';
		if(sscanf(buf, "%d%d", &max_stat, &max_letter) == 2)
			break;
	}

	rules = malloc(sizeof(rule_t*) * (max_stat+1));
	rules[0] = malloc(sizeof(rule_t) * (max_stat+1) * (max_letter+1));
	for(i=1;i<=max_stat;i++)
		rules[i] = rules[i-1]+(max_letter+1);
	for(i=0;i<(max_stat+1) * (max_letter+1);i++)
		rules[0][i].next_stat = STAT_REJECT;
	while(fgets(buf, 99, f) != NULL) {
		p = strchr(buf, '#');
		if(p != NULL)
			*p = '\0';
		if(sscanf(buf, "%d%9s%9s%9s%9s", &stat, s_letter, s_next_stat, s_next_letter, s_dir) != 5) 
			continue;
		if(s_letter[0] >= '0' && s_letter[0] <= '9') {
			sscanf(s_letter, "%d", &letter);
			if(s_next_stat[0] >= '0' && s_next_stat[0] <= '9') {
				sscanf(s_next_stat, "%d", &next_stat);
			} else {
				next_stat = stat;
			}
			if(s_next_letter[0] >= '0' && s_next_letter[0] <= '9') {
				sscanf(s_next_letter, "%d", &next_letter);
			} else {
				next_letter = letter;
			}
			if(s_dir[0] == 'R' || s_dir[0] == 'r' || s_dir[0] == '0')
				dir = 0;
			else
				dir = 1;
			rules[stat][letter].next_stat = next_stat;
			rules[stat][letter].next_letter = next_letter;
			rules[stat][letter].dir = dir;
		} else {
			for(letter=1;letter<=max_letter;letter++) {
				if(s_next_stat[0] >= '0' && s_next_stat[0] <= '9') {
					sscanf(s_next_stat, "%d", &next_stat);
				} else {
					next_stat = stat;
				}
				if(s_next_letter[0] >= '0' && s_next_letter[0] <= '9') {
					sscanf(s_next_letter, "%d", &next_letter);
				} else {
					next_letter = letter;
				}
				if(s_dir[0] == 'R' || s_dir[0] == 'r' || s_dir[0] == '0')
					dir = 0;
				else
					dir = 1;
				rules[stat][letter].next_stat = next_stat;
				rules[stat][letter].next_letter = next_letter;
				rules[stat][letter].dir = dir;
			}
		}
	}

	fclose(f);
	return 0;
}

int read_language(void)
{
	unsigned char c;
	int i;

	tape_len = STEP_ALLOC;
	tape = malloc(tape_len);
	memset(tape, BLANK, tape_len);

	i = 0;
	while(scanf("%hhi", &c)==1) {
#ifdef TRACE
		fprintf(stderr, "tape[%d] <= 0x%02hhx\n", i, c);
#endif
		if(i >= tape_len) {
			tape_len += STEP_ALLOC;
			tape = realloc(tape, tape_len);
			memset(tape+tape_len-STEP_ALLOC, BLANK, STEP_ALLOC);
		}
		tape[i++] = c;
	}
	return 0;
}

int output_result(FILE *f)
{
	int i, j;

	for(j=tape_len-1;j>=0;j--)
		if(tape[j] != BLANK)
			break;
	if(j<tape_pos)
		j = tape_pos;
	fprintf(f, "TAPE:\n");
	for(i=0;i<=j;i++) {
		if(i==tape_pos)
			fprintf(f, "[%02hhx] ", tape[i]);
		else
			fprintf(f, "%02hhx   ", tape[i]);
		if(i%16 == 15)
			fprintf(f, "\n");
	}
	fprintf(f, "\n");
	return 0;
}


int run_turing_machine(void)
{
	rule_t *p;

	current_stat = STAT_INIT;
	while(1) {
#ifdef TRACE
		fprintf(stderr, "\ncurrent_stat = %d tape_pos = %d \n", current_stat, tape_pos);
		output_result(stderr);
#endif
		p = &rules[current_stat][tape[tape_pos]];
		current_stat = p->next_stat;
		tape[tape_pos] = p->next_letter;
#ifdef TRACE
		fprintf(stderr, "tape[%d] <= %d\n", tape_pos, (int)p->next_letter);
#endif
		if(current_stat == STAT_ACCEPT || current_stat == STAT_REJECT)
			return current_stat;
		if(p->dir == (char)0) {
			tape_pos++;
#ifndef BELIEVE_ENOUGH_TAPE
			if(tape_pos == tape_len) {
				tape_len += STEP_ALLOC;
				tape = realloc(tape, tape_len);
				memset(tape+tape_len-STEP_ALLOC, BLANK, STEP_ALLOC);
			}
#endif
		} else {
#ifndef BELIEVE_ENOUGH_TAPE
			if(tape_pos == 0) {
				printf("WRONG! It's the ending of the tape\n");
				exit(1);
			}
#endif
			tape_pos--;
		}
	}
}

int main(int argc, char **argv)
{
	int ret;

	read_rules(argv[1]);
	read_language();
	ret = run_turing_machine();
	switch(ret) {
		case STAT_ACCEPT:
			printf("\nACCEPT!\n");
			break;
		case STAT_REJECT:
			printf("\nREJECT!\n");
			break;
		default:
			printf("\nWRONG! ret=%d\n", ret);
			return 1;
	}
	output_result(stdout);
	free(tape);
	free(rules[0]);
	free(rules);
	return 0;
}
