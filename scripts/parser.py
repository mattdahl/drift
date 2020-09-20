import os
import sys
import regex as re

BASE_DIRECTORY = '/Users/mattdahl/Documents/nd/research/projects/drift/project/'
RAW_DIRECTORY = os.path.join(BASE_DIRECTORY, 'corpus/raw/')
PARSED_DIRECTORY = os.path.join(BASE_DIRECTORY, 'corpus/parsed/')

REPORTER_REGEX = r'(?<=Reporter)(.*?)(?=\n\n\n)'


def parse():
    # Parse all files in the opinions directory
    justice_directories = [d for d in os.listdir(RAW_DIRECTORY) if not d.startswith('.')]
    for justice_directory in justice_directories:
        sub_directory = os.path.join(RAW_DIRECTORY, justice_directory)
        file_names = [f for f in os.listdir(sub_directory) if not f.startswith('.')]

        for file_name in file_names:
            print(os.path.join(sub_directory, file_name))
            parse_opinion(
                file_path=os.path.join(sub_directory, file_name),
                file_name=file_name,
                justice_name=justice_directory
            )


def parse_opinion(file_path, file_name, justice_name):
    # Get the file's text
    file = open(file_path)
    opinion_text = file.read()
    file.close()

    # Create the justice regex
    JUSTICE_REGEX = build_justice_regex(justice_name)

    # Remove brackets with stars between them
    opinion_text = re.sub(r'\s\[(\*)*(\d)*(\*)*\]\s', '', opinion_text)

    # Remove the Reporter heading
    opinion_text = re.sub(REPORTER_REGEX, '', opinion_text, flags=re.DOTALL | re.IGNORECASE)
    # print(opinion_text)
    # print(JUSTICE_REGEX)

    # Search for the justice's opinion
    justice_opinion = re.search(JUSTICE_REGEX, opinion_text, flags=re.DOTALL | re.IGNORECASE)
    if justice_opinion is None:
        sys.exit('Error! No opinion found.')
    else:
        justice_opinion = justice_opinion.group() # Take the first (only) extracted opinion
        if ':' in justice_opinion[0:30]:
            justice_opinion = justice_opinion.split(':', 1)[1] # Cut off the rest of its header

    # Write the opinion to file
    file = open(os.path.join(PARSED_DIRECTORY, justice_name, file_name), 'w')
    file.write(justice_opinion)
    file.close()


def build_justice_regex(justice_name):
    # Regex explanation:
    # `beginning` is a string that forms a positive lookbehind (possible beginning of the opinion)
    # (.*?) is a lazy capturing group (the opinion)
    # `end` is an array of strings that together form alternatives for a positive lookahead (end the opinion)
    ## N.B. concatenating regexes like this is not efficient. However, this is a quick hack to make things work
    beginning = [
        '{0}, Circuit Judge'.format(justice_name),
        'Justice {0}, concurring'.format(justice_name),
        'Justice {0}, dissenting'.format(justice_name),
        'Justice {0}, special'.format(justice_name),
        '{0}, Justice, concurring'.format(justice_name),
        '{0}, Justice, dissenting'.format(justice_name),
        '{0}, Justice (concurring'.format(justice_name),
        '{0}, Justice (dissenting'.format(justice_name),
        '{0}, Justice (special'.format(justice_name),
        '{0}, Judge, concurring'.format(justice_name),
        '{0}, Judge, dissenting'.format(justice_name),
        '{0}, Judge, special'.format(justice_name),
        '{0}, Judge ('.format(justice_name),
        '{0}, Chief Judge, concurring'.format(justice_name),
        '{0}, Chief Judge, dissenting'.format(justice_name),
        '{0}, J., concurring'.format(justice_name),
        '{0}, J., dissenting'.format(justice_name),
        '{0}, J., affirming'.format(justice_name),
        '{0}, J. (concurring'.format(justice_name),
        '{0}, J. (dissent'.format(justice_name),
        '{0}, J. (special'.format(justice_name),
        '{0}, J., (concur'.format(justice_name),
        '{0}, J., (dissent'.format(justice_name),
        '{0}, J., (special'.format(justice_name),
        '{0}, J., special'.format(justice_name),
        '{0}, J., concurs'.format(justice_name),
        '{0}, C.J., concurring'.format(justice_name),
        '{0}, C.J., dissenting'.format(justice_name),
        '{0}, C.J., special'.format(justice_name),
        '{0}, CJ., concurring'.format(justice_name),
        '{0}, CJ., dissenting'.format(justice_name),
        '{0}, C.J. (concurring'.format(justice_name),
        '{0}, C.J. (dissenting'.format(justice_name),
        'J. {0}, concurring'.format(justice_name),
        'J. {0}, dissenting'.format(justice_name),
        'Judge {0}, concurring'.format(justice_name),
        'Judge {0}, dissenting'.format(justice_name),
        '{0}, dissenting in part'.format(justice_name),
        '{0}, concurring in'.format(justice_name),
        'Justice {0}, opinion of the Court in part:'.format(justice_name),
        '{0}, Chief Judge:'.format(justice_name),
        'Concur by: Don R. Willett',
        'Dissent by: Don R. Willett',
        'Concur by: Young',
        'Dissent by: Young',
        'YOUNG, J., dissents and states',
        'Concur by: Robert P. Young',
        'Dissent by: Robert P. Young',
        'JUSTICE EID dissents.',
        'JUSTICE EID dissenting',
        'Justice Lee, filed a'
    ]
    end = [
        ', Circuit Judge,',
        ', Circuit Judges,',
        'End of Document',
        'Dissent by:',
        ', Senior Circuit Judge:',
        'OPINION DELIVERED:'
        'filed a'
    ]

    # Build the justice regex string
    return r'(?<=' + '|'.join([re.escape(s) for s in beginning]) + ')(.*?)(?=' + '|'.join([re.escape(s) for s in end]) + ')'


# Run
parse()
