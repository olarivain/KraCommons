//
//  NSString+extensions.m

//
//  Created by kra on 11/4/08.
//  Copyright 2008 kra.. All rights reserved.
//

#import "NSString+Replacement.h"
#import <string.h>

@implementation NSString (Replacement)

+ (NSString *) kc_localizedString: (NSString *) key
					bySubstituting: (NSArray *) substitutions {
	NSString *string = NSLocalizedString(key, nil);
	return [string kc_stringBySubstituting: substitutions];
}

- (NSString *) kc_stringBySubstituting:(NSArray *)substitutions {
	if(substitutions.count == 0) {
		return [self copy];
	}
	
	NSMutableString *substituted = [self mutableCopy];
	for(NSInteger i = 0; i < substitutions.count; i++) {
#ifdef  __IPHONE_MIN_VERSION_REQUIRED
		NSString *replacement = @"{%i}";
#else
		NSString *replacement = @"{%li}";
#endif
		[substituted replaceOccurrencesOfString: [NSString stringWithFormat: replacement, i]
									 withString: [substitutions boundSafeObjectAtIndex: i]
										options: 0
										  range: NSMakeRange(0, substituted.length)];
	}
	
	return substituted;
}

// this method will sanitize an HTML string
// it turns entities into the characters they represent
// turns <br>s into newlines
// and strips all other HTML tags
- (NSString *)kc_stringByReplacingHTMLTags {
	// our conversion is only ever going to shrink the string
	// so let's make a mutable buffer the same size and copy bytes there
	const char *source = [self UTF8String];
	char *dest = (char *)malloc(sizeof(char) * (strlen(source) + 1));
	char *destOrig = dest;
	int state = 0;
	char c;
	char *tmp; // used to point to the end of the entity/tag text that we're storing after the dest pointer
	//iconv_t cd = iconv_open("UTF-8", "UTF-32LE");
	while (*source != '\0') {
		c = *source++;
		switch (state) {
			case 0: // default
				switch (c) {
					case '<':
						// make sure this isn't a bare <
						// let's just test for the presence of an alphabetic character following it
						if (*source == '/' || isalpha(*source)) {
							state = 10;
							tmp = dest;
							*tmp++ = c; // save this here in case our tag goes unfinished
						} else {
							*dest++ = c;
						}
						break;
					case '&':
						state = 20;
						tmp = dest;
						*tmp++ = '&'; // save this here in case it's a bare &
						break;
					default:
						*dest++ = c;
				}
				break;
			case 10: // inside a tag
			case 11: // in a tag, after the space
				switch (c) {
					case '>':
						state = 0;
						*tmp = '\0';
						if (!strcmp(dest+1, "br")) {
							// it's a <br> so insert a newline
							*dest++ = '\n';
						} else {
							// it's another tag, so just strip it
							// in other words, do nothing
						}
						break;
					case ' ':
						state = 11;
						break;
					case '"':
						state = 12;
						break;
					case '\'':
						state = 13;
						break;
					default:
						if (state == 10) {
							*tmp++ = c;
						}
				}
				break;
			case 12: // in a tag, between double-quotes
				switch (c) {
					case '"':
						state = 11;
						break;
				}
				break;
			case 13: // in a tag, between single-quotes
				switch (c) {
					case '\'':
						state = 11;
						break;
				}
				break;
			case 20: // in an entity
				switch (c) {
					case ';':
						// the entity is over
						state = 0;
						*tmp = '\0';
						tmp = dest+1;
						if (!strcmp(tmp, "amp")) {
							// we already have & after dest
							dest++;
						} else if (!strcmp(tmp, "lt")) {
							*dest++ = '<';
						} else if (!strcmp(tmp, "gt")) {
							*dest++ = '>';
						} else if (!strcmp(tmp, "quot")) {
							*dest++ = '"';
						} else if (!strncmp(tmp, "#", 1)) {
							tmp++;
							int ishex = 0;
							if (*tmp == 'x' || *tmp == 'X') {
								ishex = 1;
								tmp++;
							}
							int isnum = 1;
							for (char *digit = tmp; *digit != '\0'; digit++) {
								if (!isdigit(*digit) && (!ishex || !((*digit >= 'a' && *digit <= 'f') ||
																	 (*digit >= 'A' && *digit <= 'F')))) {
									isnum = 0;
									break;
								}
							}
							if (*tmp != '\0' && isnum) {
								/*unsigned int num = NSSwapHostIntToLittle(strtol(tmp, NULL, 10));
								 char *code = (char *)(&num);
								 size_t inbytes = sizeof(int);
								 size_t outbytes = 4;
								 char utf8code[outbytes];
								 char *outbuf = utf8code;
								 if (iconv(cd, &code, &inbytes, &outbuf, &outbytes) < 0) {
								 // the conversion failed for some reason
								 // just ignore it and move on - we don't particularly care,
								 // especially since we have no way of recovering
								 } else {
								 // successful conversion
								 size_t len = outbuf - utf8code;
								 memmove(dest, utf8code, len);
								 dest += len;
								 }*/
								unsigned long long uc = strtoll(tmp, NULL, (ishex ? 16 : 10));
								if (uc >= 0xD800 && uc <= 0xDF00) {
									// it's part of a surrogate pair
									// for some godforsaken reason, WebKit actually attempts to interpret an entity in this range
									// as part of a surrogate pair, but it's just causing us problems to do the same, so ignore
									// these characters
								} else {
									const char *ucs;
									if (uc > 0xFFFF) {
										// split it up into a surrogate pair
										uc -= 0x10000;
										unichar low = (uc & 0x3FF) + 0xDC00;
										unichar high = (uc >> 10) + 0xD800;
										unichar pair[] = { high, low };
										ucs = [[NSString stringWithCharacters:pair length:2] UTF8String];
									} else {
										ucs = [[NSString stringWithCharacters:(const unichar*)&uc length:1] UTF8String];
									}
									size_t len = strlen(ucs);
									memmove(dest, ucs, len);
									dest += len;
								}
							}
						}
						break;
					default:
						*tmp++ = c;
						if (!(isalpha(c) || isdigit(c) || c == '#')) {
							// looks like we had a bare &
							dest = tmp;
							state = 0;
						}
				}
		}
	}
	if (state != 0) {
		// we ended in an unterminated entity/tag
		// let's assume it was bare instead
		dest = tmp;
	}
	//iconv_close(cd);
	NSString *result = [[NSString alloc] initWithBytesNoCopy:destOrig length:(dest - destOrig) encoding:NSUTF8StringEncoding freeWhenDone:YES];
	return result;
}


/*--------------------------------------------------------------------------------------------*/
// Returns current string with all spaces removed.
/*--------------------------------------------------------------------------------------------*/ 

- (NSString *) kc_stringByTrimmingSpaces {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
